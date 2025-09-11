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
        } catch {
            print("USDZ 파일 저장 실패: \(error.localizedDescription)")
        }
    }
    
    private func showScanResult(_ room: CapturedRoom) {
        let alert = UIAlertController(
            title: "스캔 완료!",
            message: "방 스캔이 완료되었습니다.\nUSDZ 파일이 저장되었습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
