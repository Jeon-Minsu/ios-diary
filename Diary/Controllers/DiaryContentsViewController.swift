//
//  DiaryContentsViewController.swift
//  Diary
//
//  Created by Finnn, 수꿍 on 2022/08/16.
//

import UIKit
import CoreData



final class DiaryContentsViewController: UIViewController {
    
    // MARK: - Properties
        
    var currentDate: Date?
    var isEditingMemo: Bool = false
    var isDeleted: Bool = false
    var diary: Diary?
    var diaryView: DiaryListView?
    var delegate: SendUpdateProtocol?
    
    private let diaryContentView = DiaryContentView()
    
    var textViewCurrentSelectedTextRange: UITextRange?
    
    // MARK: Life Cycle
    
    override func loadView() {
        view = diaryContentView
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        configureNotificationCenter()
        setObserver()
        diaryContentView.textView.delegate = self

        guard let diary = diary else {
            currentDate = Date()
            return
        }
        currentDate = diary.createdAt
    }
    
    private func setObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(resignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func resignActive() {
        guard !diaryContentView.textView.text.isEmpty else {
            return
        }
        
        let fullText = diaryContentView.textView.text ?? ""
        
        var title: String = fullText
        var body: String = ""
        
        if fullText.contains("\n") {
            let lineBreakIndex = fullText.firstIndex(of: "\n")
            let firstLineBreakIndexInt = lineBreakIndex!.utf16Offset(in: fullText)
            let titleRange = NSMakeRange(0, firstLineBreakIndexInt)
            title = (fullText as NSString).substring(with: titleRange)
            
            let bodyRange = NSMakeRange(firstLineBreakIndexInt + 1, fullText.count - title.count - 1)
            body = (fullText as NSString).substring(with: bodyRange)
        }
        
        
        guard let _ = CoreDataManager.shared.fetchDiary(createdAt: currentDate!) else {
            CoreDataManager.shared.saveDiary(title: title, body: body, createdAt: currentDate!)
            return
        }
        
        CoreDataManager.shared.update(title: title, body: body, createdAt: currentDate!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isEditingMemo == false {
            diaryContentView.textView.becomeFirstResponder()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        guard !diaryContentView.textView.text.isEmpty else {
            return
        }
        
        let fullText = diaryContentView.textView.text ?? ""
        
        var title: String = fullText
        var body: String = ""
        
        if fullText.contains("\n") {
            let lineBreakIndex = fullText.firstIndex(of: "\n")
            let firstLineBreakIndexInt = lineBreakIndex!.utf16Offset(in: fullText)
            let titleRange = NSMakeRange(0, firstLineBreakIndexInt)
            title = (fullText as NSString).substring(with: titleRange)
            
            let bodyRange = NSMakeRange(firstLineBreakIndexInt + 1, fullText.count - title.count - 1)
            body = (fullText as NSString).substring(with: bodyRange)
        }
        
        guard let _ = CoreDataManager.shared.fetchDiary(createdAt: currentDate!) else {
            if isDeleted == false {
                CoreDataManager.shared.saveDiary(title: title, body: body, createdAt: currentDate!)
            }
            return
        }
        
        if isDeleted == true {
            CoreDataManager.shared.delete(createdAt: currentDate!)
        }
        
        CoreDataManager.shared.update(title: title, body: body, createdAt: currentDate!)
    }
    
    // MARK: - Methods
    
    private func configureNavigationItems() {
        title = NavigationItem.diaryTitle
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: SystemImage.ellipsisCircle),
            style: .plain,
            target: self,
            action: #selector(sharedButtonTapped)
        )
    }
    
    @objc private func sharedButtonTapped() {
        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)

        let shareAction = UIAlertAction(title: "Share...",
                                        style: .default) { [self] _ in
            
            let activityViewController = UIActivityViewController(activityItems: [self.diaryContentView.textView.text!], applicationActivities: nil)
            activityViewController.modalPresentationStyle = .formSheet
            activityViewController.navigationController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
            self.present(activityViewController, animated: true)
        }

        let deleteAction = UIAlertAction(title: "Delete",
                                         style: .destructive) { _ in

            let alert = UIAlertController(title: "진짜요?", message: "정말로 삭제하시겠어요?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "취소", style: .cancel)
            let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.isDeleted = true
                self.navigationController?.popViewController(animated: true)
            }

            alert.addAction(cancelAction)
            alert.addAction(deleteAction)

            self.present(alert, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)

        actionSheet.addAction(shareAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)

        present(actionSheet,
                animated: true,
                completion: nil)
    }
    
    private func configureUI() {

        title = diary?.createdAt == nil
            ? Date().localizedString
            : diary?.createdAt!.localizedString
        
        guard let diaryTitle = diary?.title,
              let diaryBody = diary?.body else {
            diaryContentView.textView.text = ""
            return
        }
        
        let titleAttrString = NSMutableAttributedString(string: diaryTitle, attributes: [NSMutableAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title1)])
        let bodyAttrString = NSMutableAttributedString(string: "\n" + diaryBody, attributes: [NSMutableAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)])
        
        let attrText = NSMutableAttributedString()
        attrText.append(titleAttrString)
        attrText.append(bodyAttrString)
        diaryContentView.textView.attributedText = attrText
    }
    
    private func configureNotificationCenter() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let contentInset = UIEdgeInsets(top: 0.0,
                                        left: 0.0,
                                        bottom: keyboardFrame.size.height,
                                        right: 0.0)
        
        diaryContentView.textView.contentInset = contentInset
        diaryContentView.textView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide() {
        let contentInset = UIEdgeInsets.zero
        
        diaryContentView.textView.contentInset = contentInset
        diaryContentView.textView.scrollIndicatorInsets = contentInset
        
        guard !diaryContentView.textView.text.isEmpty else {
            return
        }
        
        let fullText = diaryContentView.textView.text ?? ""
        
        var title: String = fullText
        var body: String = ""
        
        if fullText.contains("\n") {
            let lineBreakIndex = fullText.firstIndex(of: "\n")
            let firstLineBreakIndexInt = lineBreakIndex!.utf16Offset(in: fullText)
            let titleRange = NSMakeRange(0, firstLineBreakIndexInt)
            title = (fullText as NSString).substring(with: titleRange)
            
            let bodyRange = NSMakeRange(firstLineBreakIndexInt + 1, fullText.count - title.count - 1)
            body = (fullText as NSString).substring(with: bodyRange)
        }
        
        guard let _ = CoreDataManager.shared.fetchDiary(createdAt: currentDate!) else {
            CoreDataManager.shared.saveDiary(title: title, body: body, createdAt: currentDate!)
            return
        }
        
        CoreDataManager.shared.update(title: title, body: body, createdAt: currentDate!)
    }
}

protocol SendUpdateProtocol: AnyObject {
    func sendUpdated()
}

extension DiaryContentsViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // 비교용 폰트
        let title1Font = UIFont.preferredFont(forTextStyle: .title1)
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        
        // 현재 커서 (위치, 길이)
        let cursorLocation = textView.selectedRange.location
        let cursorLength = textView.selectedRange.length
        
        // 총 텍스트 길이
        let textLength = textView.attributedText.length - 1
        
        // Text View의 텍스트, 커서 위치 가져오기
        guard let textViewString = textView.text,
              let selectedTextRange = textView.selectedTextRange else {
            return true
        }
        
        // 현재 커서 위치의 offset
        let offset = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
        // offset(Int)값으로 String.Index 구하기
        let cursorIndex = textViewString.index(textViewString.startIndex, offsetBy: offset)
        
        // 커서 위치로부터 왼쪽, 오른쪽의 모든 텍스트(String)
        let cursorsLeftString = textViewString[textViewString.startIndex..<cursorIndex]
        let cursorsRightString = textViewString[cursorIndex..<textViewString.endIndex]
        // 커서 바로 오른쪽의 문자(Character)
        let cursorsRightCharacter = cursorsRightString.first
        
        
        
        
        // 백스페이스를 누른 경우
        if text == "" {
            
            // 텍스트 길이가 현재 커서의 위치보다 큰 경우 (== 커서가 문자열 "안쪽"에 있음)
            // 커서의 길이가 0인 경우 (== 범위가 아닌, 한 지점을 선택함)
            // 커서 바로 오른쪽의 문자가 "\n"가 아닌 경우 (== 바로 다음이 개행문자가 아닌 일반적인 문자인 경우)
            if textLength > cursorLocation && cursorLocation > 1 && cursorLength <= 0 && cursorsRightCharacter != "\n" {
                
                // 커서 왼쪽, 오른쪽 문자의 Font 가져오기
                guard let cursorsLeftFont = textView.attributedText.attribute(.font, at: cursorLocation - 2, effectiveRange: nil) as? UIFont,
                      let cursorsRightFont = textView.attributedText.attribute(.font, at: cursorLocation, effectiveRange: nil) as? UIFont else {
                    return true
                }
                
                // 폰트 사이즈가 다른 경우 (== 폰트가 다름)
                if cursorsLeftFont.pointSize != cursorsRightFont.pointSize {
                    
                    // 현재의 커서 위치 저장
                    self.textViewCurrentSelectedTextRange = textView.selectedTextRange

                    // Title, Body 텍스트를 쌓을 문자열을 생성
                    var titleText: String = ""
                    var bodyText: String = ""

                    // 텍스트 안에 있는 모든 attributedText를 돌아가면서 확인
                    let allTextRange = NSRange(location: 0, length: textView.text.count)
                    textView.attributedText.enumerateAttributes(in: allTextRange) { value, range, pointer in
                        guard let font = value[.font] as? UIFont else { return }
                        let text = textView.attributedText.attributedSubstring(from: range).string
                        
                        // 폰트사이즈가 Title인지 Body인지 구분
                        switch font.pointSize {
                        case title1Font.pointSize:
                            titleText += text
                        case bodyFont.pointSize:
                            bodyText += text
                        default:
                            break
                        }
                    }
                    
                    // "\n" 를 기준으로 문자열 나누기
                    var splitedBodyText = bodyText.split(separator: "\n")
                    
                    // body의 첫번째 줄을 잘라서 title의 뒷부분에 붙이기
                    if let firstLineOfBodyText = splitedBodyText.first {
                        titleText += firstLineOfBodyText
                        splitedBodyText.removeFirst()
                    }
                    
                    // 첫 번째줄을 없앤 body 문자열 다시 합치기
                    let fixedBodyText = splitedBodyText.joined(separator: "\n")

                    // 재 생성한 문자열로 Attributed String 재생성
                    let attributedTitle = NSMutableAttributedString(string: titleText, attributes: [NSAttributedString.Key.font: title1Font])
                    let attributedBody = NSMutableAttributedString(string: "\n" + fixedBodyText, attributes: [NSAttributedString.Key.font: bodyFont])

                    let fixedAttributedText = NSMutableAttributedString()
                    fixedAttributedText.append(attributedTitle)
                    fixedAttributedText.append(attributedBody)
                    
                    // Text View에 적용
                    textView.attributedText = NSAttributedString(attributedString: fixedAttributedText)

                    // 중복 입력 방지
                    return false
                }
            }
        }

        
        
        // "\n"(엔터)가 입력된 경우
        if text == "\n" {
            // Text View의 Attributed Text
            let attributedText = textView.attributedText

            // 텍스트 길이가 현재 커서의 위치보다 큰 경우 (== 커서가 문자열 "안쪽"에 있음)
            // 커서의 길이가 0인 경우 (== 범위가 아닌, 한 지점을 선택함)
            if textLength > cursorLocation && cursorLocation > 0 {
                
                // 커서 왼쪽, 오른쪽 문자의 Font 가져오기
                guard let cursorsLeftFont = attributedText?.attribute(.font, at: cursorLocation - 1, effectiveRange: nil) as? UIFont,
                      let cursorsRightFont = attributedText?.attribute(.font, at: cursorLocation, effectiveRange: nil) as? UIFont else {
                    return true
                }

                // 폰트 사이즈가 다른 경우 (== 폰트가 다름)
                if cursorsLeftFont.pointSize != cursorsRightFont.pointSize {
                    // 커서 오른쪽에 있는 문자의 폰트를 그대로 적용
                    textView.typingAttributes = [NSAttributedString.Key.font: cursorsRightFont]
                }
            
            // 텍스트 길이가 현재 커서의 위치와 같은 경우 (== 커서가 문자열 "끝"에 있음)
            } else {
                // body 폰트로 적용
                textView.typingAttributes = [NSAttributedString.Key.font: bodyFont]
            }
        }
        
        // 커서 왼쪽에 아무런 문자열도 없는 경우 (== 시작 위치에 있음)
        if cursorsLeftString.replacingOccurrences(of: "\n", with: "").count <= 0 {
            // Title 폰트로 적용
            textView.typingAttributes = [NSAttributedString.Key.font: title1Font]
        }
        
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        
        // 백스페이스 눌러서 AttributedText가 재설정된 경우 커서 위치 원래 위치로 옮기기
        // textViewSelectedRange 값이 있는 경우 (== 커서 위치가 조정됨)
        if let textViewSelectedRange = textViewCurrentSelectedTextRange,
           let newPosition = textView.position(from: textViewSelectedRange.start, offset: -1) {
            
            // 저장해놨던 위치로 커서를 옮기고, nil로 다시 설정
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
            self.textViewCurrentSelectedTextRange = nil
        }
    }
}

