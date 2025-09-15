import UIKit
import QuickLook

class FileManagerViewController: UIViewController {
    
    // MARK: - Properties
    private let directoryURL: URL
    private var files: [URL] = []
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        return tableView
    }()
    
    private lazy var refreshButton: UIBarButtonItem = {
        return UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshButtonTapped)
        )
    }()
    
    // MARK: - Initialization
    init(directoryURL: URL) {
        self.directoryURL = directoryURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFiles()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation Bar 설정
        title = "저장된 파일들"
        navigationItem.rightBarButtonItem = refreshButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        // TableView 설정
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func refreshButtonTapped() {
        loadFiles()
    }
    
    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - File Management
    private func loadFiles() {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // USDZ 파일만 필터링하고 생성 날짜순으로 정렬
            files = contents
                .filter { $0.pathExtension.lowercased() == "usdz" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2 // 최신 파일이 위에 오도록
                }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        } catch {
            print("파일 목록 로드 실패: \(error.localizedDescription)")
            showAlert(title: "오류", message: "파일 목록을 불러올 수 없습니다: \(error.localizedDescription)")
        }
    }
    
    private func getFileInfo(for url: URL) -> (size: String, date: String) {
        let fileManager = FileManager.default
        
        // 파일 크기
        var sizeString = "알 수 없음"
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB]
                formatter.countStyle = .file
                sizeString = formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("파일 크기 확인 실패: \(error.localizedDescription)")
        }
        
        // 파일 날짜
        var dateString = "알 수 없음"
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let creationDate = attributes[.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.locale = Locale(identifier: "ko_KR")
                dateString = formatter.string(from: creationDate)
            }
        } catch {
            print("파일 날짜 확인 실패: \(error.localizedDescription)")
        }
        
        return (sizeString, dateString)
    }
    
    private func showFileOptions(for url: URL) {
        let alert = UIAlertController(title: "파일 옵션", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "미리보기", style: .default) { _ in
            self.previewFile(url)
        })
        
        alert.addAction(UIAlertAction(title: "공유", style: .default) { _ in
            self.shareFile(url)
        })
        
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
            self.deleteFile(url)
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad에서 popover로 표시
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func previewFile(_ url: URL) {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        present(previewController, animated: true)
    }
    
    private func shareFile(_ url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // iPad에서 popover로 표시
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func deleteFile(_ url: URL) {
        let alert = UIAlertController(
            title: "파일 삭제",
            message: "정말로 이 파일을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
            do {
                try FileManager.default.removeItem(at: url)
                self.loadFiles()
                print("파일 삭제 완료: \(url.lastPathComponent)")
            } catch {
                self.showAlert(title: "삭제 실패", message: "파일을 삭제할 수 없습니다: \(error.localizedDescription)")
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FileManagerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        let fileURL = files[indexPath.row]
        
        let fileInfo = getFileInfo(for: fileURL)
        
        cell.textLabel?.text = fileURL.lastPathComponent
        cell.detailTextLabel?.text = "\(fileInfo.size) • \(fileInfo.date)"
        cell.accessoryType = .disclosureIndicator
        
        // USDZ 파일 아이콘
        cell.imageView?.image = UIImage(systemName: "cube.box")
        cell.imageView?.tintColor = .systemBlue
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FileManagerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let fileURL = files[indexPath.row]
        showFileOptions(for: fileURL)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if files.isEmpty {
            return "저장된 USDZ 파일이 없습니다.\n방을 스캔하여 첫 번째 파일을 만들어보세요!"
        }
        return "총 \(files.count)개의 USDZ 파일"
    }
}

// MARK: - QLPreviewControllerDataSource
extension FileManagerViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // 현재 선택된 파일의 URL을 반환
        if let indexPath = tableView.indexPathForSelectedRow {
            return files[indexPath.row] as QLPreviewItem
        }
        return files.first! as QLPreviewItem
    }
}

// MARK: - QLPreviewControllerDelegate
extension FileManagerViewController: QLPreviewControllerDelegate {
    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        // 미리보기 종료 시 선택 해제
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
