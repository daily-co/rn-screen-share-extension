import Foundation

// This class has been created using this article as guide:
// https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-ios-sdk/#screen-sharing-integration

// Copyright © 2021 Atlassian Inc. All rights reserved.
// Modifications copyright © 2023 Daily, Co.
// Changes that have been made:
// - Refactored to don't use extensions;
// - Refactored the way that we are addressing the mutable pointers
// - Refactored to validate the file descriptor path length using strlen
// - Created a method to check if the connection is ready
// - Using NSLog
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
final class SocketConnection: NSObject, StreamDelegate {

    var didOpen: (() -> Void)?
    var didClose: ((Error?) -> Void)?
    var streamHasSpaceAvailable: (() -> Void)?

    private let filePath: String
    private var socketFileDescriptor: Int32

    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private let networkQueue: DispatchQueue = .global(qos: .userInitiated)
    private var shouldKeepRunning: Bool = false
    let addressPointer: UnsafeMutablePointer<sockaddr_un> = .allocate(capacity: MemoryLayout<sockaddr_un>.size)

    init?(filePath path: String) {
        filePath = path
        socketFileDescriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)

        guard socketFileDescriptor != -1 else {
            NSLog("failure to create the socket")
            return nil
        }
    }

    func open() -> Bool {
        NSLog("open socket connection")
        guard FileManager.default.fileExists(atPath: filePath) else {
            NSLog("failure: socket file is missing")
            return false
        }
        guard connectSocket() == true else {
            return false
        }
        setupStreams()
        inputStream?.open()
        outputStream?.open()
        return true
    }

    func close() {
        unscheduleStreams()

        inputStream?.delegate = nil
        outputStream?.delegate = nil

        inputStream?.close()
        outputStream?.close()

        inputStream = nil
        outputStream = nil
    }

    func writeToStream(buffer: UnsafePointer<UInt8>, maxLength length: Int) -> Int {
        outputStream?.write(buffer, maxLength: length) ?? 0
    }


    private func connectSocket() -> Bool {
        self.addressPointer.pointee = sockaddr_un()

        let isValidPath = filePath.withCString { filePathCString in
            let maxPathLength = MemoryLayout.size(ofValue: self.addressPointer.pointee.sun_path)
            let pathLength = strlen(filePathCString)

            guard pathLength < maxPathLength else {
                NSLog("failure: fd path is too long (max: \(maxPathLength) bytes)")
                return false
            }

            _ = withUnsafeMutablePointer(to: &self.addressPointer.pointee.sun_path) { ptr in
                // The `cString` is a collection of bytes, including a null-terminator at the end
                // so no need to do `cString.count + 1` here:
                strncpy(ptr, filePathCString, pathLength)
            }
            return true
        }

        guard isValidPath else {
            return false
        }

        let status = self.addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { pointer in
            Darwin.connect(socketFileDescriptor, pointer, socklen_t(MemoryLayout<sockaddr_un>.size))
        }

        guard status == noErr else {
            NSLog("failure: \(status)")
            return false
        }

        return true
    }

    private func setupStreams() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocket(kCFAllocatorDefault, socketFileDescriptor, &readStream, &writeStream)

        inputStream = readStream?.takeRetainedValue()
        inputStream?.delegate = self
        inputStream?.setProperty(kCFBooleanTrue, forKey: Stream.PropertyKey(kCFStreamPropertyShouldCloseNativeSocket as String))

        outputStream = writeStream?.takeRetainedValue()
        outputStream?.delegate = self
        outputStream?.setProperty(kCFBooleanTrue, forKey: Stream.PropertyKey(kCFStreamPropertyShouldCloseNativeSocket as String))

        scheduleStreams()
    }

    private func scheduleStreams() {
        shouldKeepRunning = true
        networkQueue.async { [weak self] in
            guard let self else { return }
            self.inputStream?.schedule(in: .current, forMode: .common)
            self.outputStream?.schedule(in: .current, forMode: .common)
            RunLoop.current.run()

            var isRunning = false
            repeat {
                guard self.shouldKeepRunning else { break }
                isRunning = RunLoop.current.run(mode: .default, before: .distantFuture)
            } while (isRunning)
        }
    }

    private func unscheduleStreams() {
        networkQueue.sync { [weak self] in
            guard let self else { return }
            self.inputStream?.remove(from: .current, forMode: .common)
            self.outputStream?.remove(from: .current, forMode: .common)
        }

        shouldKeepRunning = false
    }

    private func notifyDidClose(error: Error?) {
        if let didClose {
            didClose(error)
        }
    }

    func isConnectionReady() -> Bool {
        return self.shouldKeepRunning
    }

    // Method from the Protocol StreamDelegate
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            NSLog("client stream open completed")
            if aStream == outputStream {
                didOpen?()
            }
        case .hasBytesAvailable:
            if aStream == inputStream {
                var buffer: UInt8 = 0
                let numberOfBytesRead = inputStream?.read(&buffer, maxLength: 1)
                if numberOfBytesRead == 0 && aStream.streamStatus == .atEnd {
                    NSLog("server socket closed")
                    close()
                    notifyDidClose(error: nil)
                }
            }
        case .hasSpaceAvailable:
            if aStream == outputStream {
                streamHasSpaceAvailable?()
            }
        case .errorOccurred:
            NSLog("client stream error occured: \(String(describing: aStream.streamError))")
            close()
            notifyDidClose(error: aStream.streamError)

        default:
            break
        }
    }
}

