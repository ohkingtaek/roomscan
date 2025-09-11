import UIKit
import UniformTypeIdentifiers

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    private var saveLocationLabel: UILabel!
    private var saveLocationButton: UIButton!
    private var currentPathLabel: UILabel!
    private var resetButton: UIButton!
    private var backButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSettings()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 제목 라벨
        let titleLabel = UILabel()
        titleLabel.text = "Aeris 설정"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // 저장 위치 설명 라벨
        saveLocationLabel = UILabel()
        saveLocationLabel.text = "USDZ 파일 저장 위치"
        saveLocationLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        saveLocationLabel.textAlignment = .left
        saveLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveLocationLabel)
        
        // 현재 경로 표시 라벨
        currentPathLabel = UILabel()
        currentPathLabel.text = "현재 경로를 불러오는 중..."
        currentPathLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        currentPathLabel.textColor = .secondaryLabel
        currentPathLabel.numberOfLines = 0
        currentPathLabel.textAlignment = .left
        currentPathLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentPathLabel)
        
        // 저장 위치 선택 버튼
        saveLocationButton = UIButton(type: .system)
        saveLocationButton.setTitle("📁 저장 위치 선택", for: .normal)
        saveLocationButton.setTitleColor(.white, for: .normal)
        saveLocationButton.backgroundColor = .systemBlue
        saveLocationButton.layer.cornerRadius = 12
        saveLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveLocationButton.translatesAutoresizingMaskIntoConstraints = false
        saveLocationButton.addTarget(self, action: #selector(selectSaveLocation), for: .touchUpInside)
        view.addSubview(saveLocationButton)
        
        // 기본값으로 리셋 버튼
        resetButton = UIButton(type: .system)
        resetButton.setTitle("🔄 기본값으로 리셋", for: .normal)
        resetButton.setTitleColor(.systemBlue, for: .normal)
        resetButton.backgroundColor = .systemGray6
        resetButton.layer.cornerRadius = 12
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetToDefault), for: .touchUpInside)
        view.addSubview(resetButton)
        
        // 뒤로가기 버튼
        backButton = UIButton(type: .system)
        backButton.setTitle("← 뒤로가기", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            // 제목 라벨
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 뒤로가기 버튼
            backButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // 저장 위치 설명 라벨
            saveLocationLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 40),
            saveLocationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveLocationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 현재 경로 라벨
            currentPathLabel.topAnchor.constraint(equalTo: saveLocationLabel.bottomAnchor, constant: 10),
            currentPathLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentPathLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 저장 위치 선택 버튼
            saveLocationButton.topAnchor.constraint(equalTo: currentPathLabel.bottomAnchor, constant: 20),
            saveLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveLocationButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 리셋 버튼
            resetButton.topAnchor.constraint(equalTo: saveLocationButton.bottomAnchor, constant: 15),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func selectSaveLocation() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc private func resetToDefault() {
        let alert = UIAlertController(title: "기본값으로 리셋", message: "저장 위치를 기본값(앱 Documents 폴더)으로 리셋하시겠습니까?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "리셋", style: .destructive) { [weak self] _ in
            self?.resetToDefaultLocation()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Helper Methods
    private func loadCurrentSettings() {
        if let savedPath = UserDefaults.standard.string(forKey: "USDZSavePath") {
            currentPathLabel.text = "현재 경로: \(savedPath)"
        } else {
            let defaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
            currentPathLabel.text = "현재 경로: \(defaultPath) (기본값)"
        }
    }
    
    private func saveCustomPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: "USDZSavePath")
        currentPathLabel.text = "현재 경로: \(path)"
        
        let alert = UIAlertController(title: "저장 완료", message: "USDZ 파일 저장 위치가 설정되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func resetToDefaultLocation() {
        UserDefaults.standard.removeObject(forKey: "USDZSavePath")
        let defaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        currentPathLabel.text = "현재 경로: \(defaultPath) (기본값)"
        
        let alert = UIAlertController(title: "리셋 완료", message: "저장 위치가 기본값으로 리셋되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        
        // 선택된 폴더에 쓰기 권한이 있는지 확인
        if selectedURL.startAccessingSecurityScopedResource() {
            defer { selectedURL.stopAccessingSecurityScopedResource() }
            
            // 폴더 경로 저장
            saveCustomPath(selectedURL.path)
        } else {
            let alert = UIAlertController(title: "권한 오류", message: "선택한 폴더에 접근 권한이 없습니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
}
