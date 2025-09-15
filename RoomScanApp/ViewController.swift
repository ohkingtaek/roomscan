import UIKit
import RoomPlan

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    @IBOutlet weak var startScanButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var deviceInfoLabel: UILabel!
    
    // 설정 버튼
    private var settingsButton: UIButton!
    
    // MARK: - Properties
    private var roomCaptureViewController: RoomCaptureViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkDeviceCompatibility()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        titleLabel.text = "Aeris Scan"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        
        descriptionLabel.text = "LiDAR를 사용하여 방을 3D로 스캔하고 USDZ 파일로 저장하세요"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        startScanButton.setTitle("스캔 시작", for: .normal)
        startScanButton.backgroundColor = UIColor.systemBlue
        startScanButton.setTitleColor(.white, for: .normal)
        startScanButton.layer.cornerRadius = 12
        startScanButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        deviceInfoLabel.font = UIFont.systemFont(ofSize: 14)
        deviceInfoLabel.textAlignment = .center
        deviceInfoLabel.numberOfLines = 0
        
        // 설정 버튼 추가
        setupSettingsButton()
    }
    
    private func setupSettingsButton() {
        settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙️ 설정", for: .normal)
        settingsButton.setTitleColor(.systemBlue, for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        view.addSubview(settingsButton)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Device Compatibility Check
    private func checkDeviceCompatibility() {
        if RoomCaptureSession.isSupported {
            deviceInfoLabel.text = "LiDAR 지원 기기입니다.\nRoomPlan을 사용할 수 있습니다."
            deviceInfoLabel.textColor = .systemGreen
            startScanButton.isEnabled = true
        } else {
            deviceInfoLabel.text = "LiDAR가 지원되지 않는 기기입니다.\niPhone 12 Pro 이상 또는 iPad Pro 2020 이상이 필요합니다."
            deviceInfoLabel.textColor = .systemRed
            startScanButton.isEnabled = false
            startScanButton.backgroundColor = .systemGray
        }
    }
    
    // MARK: - Actions
    @IBAction func startScanButtonTapped(_ sender: UIButton) {
        guard RoomCaptureSession.isSupported else {
            showAlert(title: "지원되지 않는 기기", message: "이 기기는 RoomPlan을 지원하지 않습니다.")
            return
        }
        
        presentRoomCaptureViewController()
    }
    
    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - Room Capture
    private func presentRoomCaptureViewController() {
        roomCaptureViewController = RoomCaptureViewController()
        roomCaptureViewController?.delegate = self
        
        if let roomCaptureVC = roomCaptureViewController {
            roomCaptureVC.modalPresentationStyle = .fullScreen
            present(roomCaptureVC, animated: true)
        }
    }
    
    // MARK: - Alert
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - RoomCaptureViewControllerDelegate
extension ViewController: RoomCaptureViewControllerDelegate {
    func roomCaptureViewController(_ roomCaptureViewController: RoomCaptureViewController, didFinishWith result: CapturedRoom) {
        // 스캔 완료 후 결과 처리
        roomCaptureViewController.dismiss(animated: true) { [weak self] in
            self?.handleScanResult(result)
        }
    }
    
    func roomCaptureViewController(_ roomCaptureViewController: RoomCaptureViewController, didFailWith error: Error) {
        // 스캔 실패 처리
        roomCaptureViewController.dismiss(animated: true) { [weak self] in
            self?.showAlert(title: "스캔 실패", message: error.localizedDescription)
        }
    }
    
    private func handleScanResult(_ result: CapturedRoom) {
        // USDZ 파일로 저장
        saveRoomAsUSDZ(result)
        
        // 결과 표시
        showScanResult(result)
    }
    
    private func saveRoomAsUSDZ(_ room: CapturedRoom) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "RoomScan_\(Date().timeIntervalSince1970).usdz"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try room.export(to: fileURL)
            print("USDZ 파일이 저장되었습니다: \(fileURL.path)")
            
            // 파일 저장 검증
            if verifyFileSaved(at: fileURL) {
                print("✅ 파일 저장 검증 성공: \(fileURL.path)")
                print("📁 파일 크기: \(getFileSize(fileURL)) bytes")
                showSaveSuccessAlert(fileURL: fileURL)
            } else {
                print("❌ 파일 저장 검증 실패")
                showSaveFailureAlert(errorMessage: "파일이 저장되었지만 검증에 실패했습니다.")
            }
        } catch {
            print("USDZ 파일 저장 실패: \(error.localizedDescription)")
            showSaveFailureAlert(errorMessage: error.localizedDescription)
        }
    }
    
    // MARK: - File Verification
    private func verifyFileSaved(at fileURL: URL) -> Bool {
        let fileManager = FileManager.default
        
        // 1. 파일 존재 여부 확인
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("❌ 파일이 존재하지 않습니다: \(fileURL.path)")
            return false
        }
        
        // 2. 파일 크기 확인 (최소 1KB 이상이어야 함)
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                print("📊 파일 크기: \(fileSize) bytes")
                if fileSize < 1024 {
                    print("❌ 파일 크기가 너무 작습니다: \(fileSize) bytes")
                    return false
                }
                return true
            } else {
                print("❌ 파일 크기 정보를 가져올 수 없습니다")
                return false
            }
        } catch {
            print("❌ 파일 속성 확인 실패: \(error.localizedDescription)")
            return false
        }
    }
    
    private func getFileSize(_ fileURL: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                return formatFileSize(fileSize)
            }
        } catch {
            print("파일 크기 확인 실패: \(error.localizedDescription)")
        }
        return "알 수 없음"
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func showSaveSuccessAlert(fileURL: URL) {
        let fileSize = getFileSize(fileURL)
        let fileName = fileURL.lastPathComponent
        
        let alert = UIAlertController(
            title: "✅ 저장 완료!",
            message: """
            USDZ 파일이 성공적으로 저장되었습니다.
            
            📁 파일명: \(fileName)
            📊 크기: \(fileSize)
            📍 경로: \(fileURL.path)
            
            파일은 앱의 Documents 폴더에 저장되었습니다.
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        alert.addAction(UIAlertAction(title: "파일 관리자 열기", style: .default) { _ in
            self.openFileManager()
        })
        
        present(alert, animated: true)
    }
    
    private func showSaveFailureAlert(errorMessage: String) {
        let alert = UIAlertController(
            title: "❌ 저장 실패",
            message: """
            USDZ 파일 저장에 실패했습니다.
            
            오류: \(errorMessage)
            
            다시 시도해주세요.
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func openFileManager() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileManagerVC = FileManagerViewController(directoryURL: documentsPath)
        let navController = UINavigationController(rootViewController: fileManagerVC)
        present(navController, animated: true)
    }
    
    private func showScanResult(_ room: CapturedRoom) {
        // 이 메서드는 더 이상 사용되지 않습니다.
        // saveRoomAsUSDZ 메서드에서 직접 성공/실패 알림을 표시합니다.
        print("스캔 결과 처리 완료")
    }
}
