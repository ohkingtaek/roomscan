import UIKit
import RoomPlan
import ARKit
import AVFoundation
import Photos
import ReplayKit

class RoomCaptureViewController: UIViewController {
    
    // MARK: - Properties
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSession: RoomCaptureSession!
    private var isScanning = false
    private var capturedRoom: CapturedRoom?
    
    // Screen Recording Properties
    private var isRecording = false
    private var screenRecorder = RPScreenRecorder.shared()
    
    // MARK: - UI Elements
    private var startStopButton: UIButton!
    private var instructionLabel: UILabel!
    private var progressView: UIProgressView!
    private var aerisStatusLabel: UILabel!
    private var aerisMessageLabel: UILabel!
    private var videoRecordButton: UIButton!
    private var videoStatusLabel: UILabel!
    
    // MARK: - Delegate
    weak var delegate: RoomCaptureViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRoomCapture()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startRoomCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRoomCapture()
        
        // 화면 녹화 중이면 중지
        if isRecording {
            stopVideoRecording()
        }
    }
    
    // MARK: - Room Capture Setup
    private func setupRoomCapture() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roomCaptureView)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        roomCaptureSession = roomCaptureView.captureSession
        roomCaptureSession.delegate = self
    }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Aeris 상태 라벨
        aerisStatusLabel = UILabel()
        aerisStatusLabel.text = "🤖 Aeris: 준비 완료"
        aerisStatusLabel.textColor = .systemGreen
        aerisStatusLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        aerisStatusLabel.textAlignment = .center
        aerisStatusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        aerisStatusLabel.layer.cornerRadius = 8
        aerisStatusLabel.clipsToBounds = true
        aerisStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(aerisStatusLabel)
        
        // Aeris 메시지 라벨
        aerisMessageLabel = UILabel()
        aerisMessageLabel.text = "안녕하세요! 저는 Aeris입니다. 방을 스캔해드릴게요."
        aerisMessageLabel.textColor = .white
        aerisMessageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        aerisMessageLabel.textAlignment = .center
        aerisMessageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        aerisMessageLabel.layer.cornerRadius = 6
        aerisMessageLabel.clipsToBounds = true
        aerisMessageLabel.numberOfLines = 0
        aerisMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(aerisMessageLabel)
        
        // 상단 인스트럭션 라벨
        instructionLabel = UILabel()
        instructionLabel.text = "방을 천천히 돌아다니며 스캔하세요"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // 진행률 표시
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // 시작/중지 버튼
        startStopButton = UIButton(type: .system)
        startStopButton.setTitle("스캔 시작", for: .normal)
        startStopButton.setTitleColor(.white, for: .normal)
        startStopButton.backgroundColor = .systemBlue
        startStopButton.layer.cornerRadius = 25
        startStopButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        startStopButton.addTarget(self, action: #selector(startStopButtonTapped), for: .touchUpInside)
        view.addSubview(startStopButton)
        
        // 화면 녹화 버튼
        videoRecordButton = UIButton(type: .system)
        videoRecordButton.setTitle("📹 화면 녹화", for: .normal)
        videoRecordButton.setTitleColor(.white, for: .normal)
        videoRecordButton.backgroundColor = .systemRed
        videoRecordButton.layer.cornerRadius = 20
        videoRecordButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        videoRecordButton.translatesAutoresizingMaskIntoConstraints = false
        videoRecordButton.addTarget(self, action: #selector(videoRecordButtonTapped), for: .touchUpInside)
        view.addSubview(videoRecordButton)
        
        // 화면 녹화 상태 라벨
        videoStatusLabel = UILabel()
        videoStatusLabel.text = "화면 녹화 준비됨"
        videoStatusLabel.textColor = .white
        videoStatusLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        videoStatusLabel.textAlignment = .center
        videoStatusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        videoStatusLabel.layer.cornerRadius = 4
        videoStatusLabel.clipsToBounds = true
        videoStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoStatusLabel)
        
        // 닫기 버튼
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        closeButton.layer.cornerRadius = 20
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            // Aeris 상태 라벨
            aerisStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            aerisStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            aerisStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            aerisStatusLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // Aeris 메시지 라벨
            aerisMessageLabel.topAnchor.constraint(equalTo: aerisStatusLabel.bottomAnchor, constant: 5),
            aerisMessageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            aerisMessageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            aerisMessageLabel.heightAnchor.constraint(equalToConstant: 60),
            
            // 인스트럭션 라벨
            instructionLabel.topAnchor.constraint(equalTo: aerisMessageLabel.bottomAnchor, constant: 10),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.heightAnchor.constraint(equalToConstant: 50),
            
            // 진행률 표시
            progressView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // 시작/중지 버튼
            startStopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startStopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            startStopButton.widthAnchor.constraint(equalToConstant: 200),
            startStopButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 비디오 촬영 버튼
            videoRecordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            videoRecordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            videoRecordButton.widthAnchor.constraint(equalToConstant: 150),
            videoRecordButton.heightAnchor.constraint(equalToConstant: 40),
            
            // 비디오 상태 라벨
            videoStatusLabel.leadingAnchor.constraint(equalTo: videoRecordButton.trailingAnchor, constant: 10),
            videoStatusLabel.centerYAnchor.constraint(equalTo: videoRecordButton.centerYAnchor),
            videoStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            videoStatusLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // 닫기 버튼
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Actions
    @objc private func startStopButtonTapped() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func videoRecordButtonTapped() {
        if isRecording {
            stopVideoRecording()
        } else {
            startVideoRecording()
        }
    }
    
    // MARK: - Room Capture Control
    private func startRoomCapture() {
        roomCaptureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    private func stopRoomCapture() {
        roomCaptureSession.stop()
    }
    
    // MARK: - Screen Recording Control
    private func startVideoRecording() {
        guard !isRecording else { return }
        
        // 화면 녹화 시작
        screenRecorder.startRecording { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.updateAerisMessage("화면 녹화 시작 실패: \(error.localizedDescription)")
                    self?.updateAerisStatus("오류", color: .systemRed)
                } else {
                    self?.isRecording = true
                    self?.updateVideoUI()
                    self?.updateAerisMessage("화면 녹화를 시작했습니다! 스캔 과정이 녹화됩니다.")
                }
            }
        }
    }
    
    private func stopVideoRecording() {
        guard isRecording else { return }
        
        screenRecorder.stopRecording { [weak self] previewViewController, error in
            DispatchQueue.main.async {
                self?.isRecording = false
                self?.updateVideoUI()
                
                if let error = error {
                    self?.updateAerisMessage("화면 녹화 중지 실패: \(error.localizedDescription)")
                    self?.updateAerisStatus("오류", color: .systemRed)
                } else {
                    self?.updateAerisMessage("화면 녹화가 완료되었습니다!")
                    self?.updateAerisStatus("완료", color: .systemGreen)
                    
                    // 미리보기 화면 표시
                    if let previewVC = previewViewController {
                        previewVC.previewControllerDelegate = self
                        self?.present(previewVC, animated: true)
                    }
                }
            }
        }
    }
    
    private func updateVideoUI() {
        if isRecording {
            videoRecordButton.setTitle("⏹️ 녹화 중지", for: .normal)
            videoRecordButton.backgroundColor = .systemOrange
            videoStatusLabel.text = "녹화 중..."
            videoStatusLabel.textColor = .systemRed
        } else {
            videoRecordButton.setTitle("📹 화면 녹화", for: .normal)
            videoRecordButton.backgroundColor = .systemRed
            videoStatusLabel.text = "화면 녹화 준비됨"
            videoStatusLabel.textColor = .white
        }
    }
    
    private func startScanning() {
        isScanning = true
        startStopButton.setTitle("스캔 중지", for: .normal)
        startStopButton.backgroundColor = .systemRed
        instructionLabel.text = "방을 천천히 돌아다니며 스캔하세요"
        
        // Aeris 메시지 업데이트
        updateAerisMessage("스캔을 시작합니다! 천천히 움직여주세요.")
        updateAerisStatus("스캔 중...", color: .systemOrange)
    }
    
    private func stopScanning() {
        isScanning = false
        startStopButton.setTitle("스캔 시작", for: .normal)
        startStopButton.backgroundColor = .systemBlue
        instructionLabel.text = "스캔을 완료하려면 '완료' 버튼을 누르세요"
        
        // Aeris 메시지 업데이트
        updateAerisMessage("스캔이 완료되었습니다! 결과를 분석하고 있습니다...")
        updateAerisStatus("분석 중...", color: .systemBlue)
        
        // 스캔 결과 처리
        if let result = capturedRoom {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.updateAerisMessage("분석 완료! 방의 구조를 성공적으로 캡처했습니다.")
                self?.updateAerisStatus("완료", color: .systemGreen)
                
                // USDZ 파일 자동 생성
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.exportToUSDZ(result)
                }
            }
            delegate?.roomCaptureViewController(self, didFinishWith: result)
        }
    }
    
    // MARK: - Aeris Helper Methods
    private func updateAerisMessage(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.aerisMessageLabel.text = message
        }
    }
    
    private func updateAerisStatus(_ status: String, color: UIColor) {
        DispatchQueue.main.async { [weak self] in
            self?.aerisStatusLabel.text = "🤖 Aeris: \(status)"
            self?.aerisStatusLabel.textColor = color
        }
    }
    
    // MARK: - USDZ Export
    private func exportToUSDZ(_ capturedRoom: CapturedRoom) {
        updateAerisMessage("USDZ 파일을 생성하고 있습니다...")
        updateAerisStatus("USDZ 생성 중...", color: .systemBlue)
        
        // USDZ 파일 생성
        let saveURL = getSaveURL()
        
        do {
            try capturedRoom.export(to: saveURL)
            updateAerisMessage("USDZ 파일이 성공적으로 저장되었습니다!")
            updateAerisStatus("완료", color: .systemGreen)
            showSaveSuccessAlert(fileURL: saveURL)
        } catch {
            updateAerisMessage("USDZ 파일 저장 실패: \(error.localizedDescription)")
            updateAerisStatus("오류", color: .systemRed)
        }
    }
    
    private func getSaveURL() -> URL {
        // 사용자가 설정한 경로가 있으면 사용, 없으면 기본 Documents 폴더 사용
        if let customPath = UserDefaults.standard.string(forKey: "USDZSavePath") {
            let customURL = URL(fileURLWithPath: customPath)
            let fileName = "Aeris_RoomScan_\(Date().timeIntervalSince1970).usdz"
            return customURL.appendingPathComponent(fileName)
        } else {
            // 기본 Documents 폴더
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "Aeris_RoomScan_\(Date().timeIntervalSince1970).usdz"
            return documentsPath.appendingPathComponent(fileName)
        }
    }
    
    private func showSaveSuccessAlert(fileURL: URL) {
        let alert = UIAlertController(title: "저장 완료", message: "USDZ 파일이 저장되었습니다.\n경로: \(fileURL.path)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        alert.addAction(UIAlertAction(title: "파일 앱에서 보기", style: .default) { _ in
            self.openInFilesApp(url: fileURL)
        })
        
        present(alert, animated: true)
    }
    
    private func openInFilesApp(url: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [url])
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true)
    }
}

// MARK: - RoomCaptureSessionDelegate
extension RoomCaptureViewController: RoomCaptureSessionDelegate {
    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        // 캡처된 방 정보 저장
        capturedRoom = room
        
        // 스캔 진행률 업데이트
        DispatchQueue.main.async { [weak self] in
            // 간단한 진행률 표시 (실제로는 더 정교한 계산이 필요)
            let progress = Float(room.walls.count + room.doors.count + room.windows.count) / 20.0
            self?.progressView.progress = min(progress, 1.0)
            
            // Aeris 메시지 업데이트
            let wallCount = room.walls.count
            let doorCount = room.doors.count
            let windowCount = room.windows.count
            
            if wallCount > 0 || doorCount > 0 || windowCount > 0 {
                let message = "벽 \(wallCount)개, 문 \(doorCount)개, 창문 \(windowCount)개를 감지했습니다!"
                self?.updateAerisMessage(message)
            }
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                self?.updateAerisMessage("죄송합니다. 스캔 중 오류가 발생했습니다: \(error.localizedDescription)")
                self?.updateAerisStatus("오류", color: .systemRed)
                self?.delegate?.roomCaptureViewController(self!, didFailWith: error)
            } else {
                // 스캔이 성공적으로 완료된 경우
                self?.updateAerisMessage("스캔이 성공적으로 완료되었습니다!")
                self?.updateAerisStatus("완료", color: .systemGreen)
                if let capturedRoom = self?.capturedRoom {
                    self?.delegate?.roomCaptureViewController(self!, didFinishWith: capturedRoom)
                }
            }
        }
    }
}

// MARK: - RPPreviewViewControllerDelegate
extension RoomCaptureViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true)
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        previewController.dismiss(animated: true)
        
        if activityTypes.contains("com.apple.UIKit.activity.SaveToCameraRoll") {
            updateAerisMessage("화면 녹화가 포토 라이브러리에 저장되었습니다!")
        } else if activityTypes.contains("com.apple.UIKit.activity.Share") {
            updateAerisMessage("화면 녹화가 공유되었습니다!")
        }
    }
}

// MARK: - Delegate Protocol
protocol RoomCaptureViewControllerDelegate: AnyObject {
    func roomCaptureViewController(_ roomCaptureViewController: RoomCaptureViewController, didFinishWith result: CapturedRoom)
    func roomCaptureViewController(_ roomCaptureViewController: RoomCaptureViewController, didFailWith error: Error)
}
