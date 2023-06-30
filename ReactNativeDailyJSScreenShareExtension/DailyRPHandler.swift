import ReplayKit
import Foundation

private enum BroadcastFinishedReason {
    case appStoppedScreenSharing
    case systemUIOrError // default assumption
}

private enum DarwinNotification: String {
    case screenCaptureStoppedBySystemUIOrError = "ScreenCaptureStoppedBySystemUIOrError"
    case screenCaptureExtensionStarted = "ScreenCaptureExtensionStarted"
}

open class DailyRPHandler: RPBroadcastSampleHandler {
    
    private let clientConnection: SocketConnection
    private let jpegUploader: JpegUploader
    private let darwinNotificationCenter: CFNotificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    private static var sampleHandlerSharedContext: DailyRPHandler?
    private var frameCount: Int = 0
    private var broadcastFinishedReason: BroadcastFinishedReason = .systemUIOrError

    public override init() {
        //do nothing, we need to receive the appGroupIdentifier
        fatalError("init(appGroupIdentifier:) has not been invoked")
    }

    public init(appGroupIdentifier: String) {
        let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        // rtc_SSFD means: real time communication screen sharing socket file descriptor,
        // It is how react-native-webrtc creates the path to estabilish the socket connection
        let socketFilePath = sharedContainer?.appendingPathComponent("rtc_SSFD").path ?? ""
        guard let connection = SocketConnection(filePath: socketFilePath) else {
            fatalError("Failed to initialize socket connection.")
        }

        clientConnection = connection
        jpegUploader = JpegUploader(connection: connection)
        
        super.init()
        
        setupConnection()
        DailyRPHandler.sampleHandlerSharedContext = self
        CFNotificationCenterAddObserver(self.darwinNotificationCenter, Unmanaged.passRetained(self).toOpaque(), { (center, observer, name, object, userInfo) in
            NSLog("Received NOTIFICATION MustStopScreenCapture")
            DailyRPHandler.sampleHandlerSharedContext?.finishBroadcastByApp()
        }, "MustStopScreenCapture" as CFString, nil, .deliverImmediately)
    }
    
    private func finishBroadcastByApp() {
        self.broadcastFinishedReason = .appStoppedScreenSharing
        // Compiling Swift framework with mixed-in Objective-C code
        // https://gist.github.com/bgromov/f4327343ad67a5f7216262ccbe99c376
        // We are invoking this method from Swift, because that is the only way to finish the broadcast without error
        // https://stackoverflow.com/questions/53669991/is-there-a-way-to-finish-broadcast-gracefully-from-within-rpbroadcastsamplehandl
        finishBroadcastGracefully(self)
    }
    
    public override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        frameCount = 0
        self.postNotification(.screenCaptureExtensionStarted)
        openConnection()
    }
    
    public override func broadcastFinished() {
        // Notify app that broadcast finished by system UI or error
        if (broadcastFinishedReason == .systemUIOrError) {
            self.postNotification(.screenCaptureStoppedBySystemUIOrError)
        }
        // Reset to default state
        broadcastFinishedReason = .systemUIOrError
        clientConnection.close()
    }
    
    public override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // very simple mechanism for adjusting frame rate by using every third frame
            frameCount += 1
            if frameCount % 3 == 0 {
                jpegUploader.send(sample: sampleBuffer)
            }
        default:
            break
        }
    }
    
    private func postNotification(_ name: DarwinNotification) {
        CFNotificationCenterPostNotification(self.darwinNotificationCenter, CFNotificationName(rawValue: name.rawValue as CFString), nil, nil, true)
    }
    
    private func setupConnection() {
        clientConnection.didClose = { [weak self] error in
            NSLog("[pk] [SampleHandler] client connection closed")
            if let error = error {
                self?.finishBroadcastWithError(error)
            } else {
                self?.finishBroadcastByApp()
            }
        }
    }
    
    private func openConnection() {
        let queue = DispatchQueue(label: "broadcast.connectTimer")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(500))
        timer.setEventHandler { [weak self] in
            guard self?.clientConnection.open() == true else {
                return
            }
            
            timer.cancel()
        }
        
        timer.resume()
    }
    
}
