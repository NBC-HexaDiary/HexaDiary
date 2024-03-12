//
//  CalendarListVC.swift
//  EveryDiary
//
//  Created by eunsung ko on 2/29/24.
//

import UIKit

import SnapKit

class CalendarListVC: UIViewController {
    var selectedDiaries: [DiaryEntry] = [] // 선택된 일기들을 저장하는 프로퍼티
    var selectedDateString: String? // 선택된 날짜를 문자열로 저장할 프로퍼티
    
    private lazy var dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.font = UIFont(name: "SFProDisplay-Bold", size: 33)
        dateLabel.textColor = .mainTheme
        return dateLabel
    }()

    private lazy var dailyListCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.layer.cornerRadius = 0
        collectionView.backgroundColor = .mainBackground
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.register(DailyListCell.self, forCellWithReuseIdentifier: DailyListCell.id)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
        addSubViewCalendarListVC()
        autoLayoutCalendarListVC()
        updateDateLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("\(String(describing: selectedDateString))")
        print("\(fetchUpdateDiaries())")
    }
    
    private func autoLayoutCalendarListVC() {
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.width.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(50)
        }
        dailyListCollectionView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(0)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(0)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(0)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(0)
        }
    }
    
    private func addSubViewCalendarListVC() {
        view.addSubview(dailyListCollectionView)
        view.addSubview(dateLabel)
    }
    
    private func fetchUpdateDiaries() {
        DiaryManager.shared.fetchDiaries { [weak self] (diaries, error) in
            guard let self = self, let diaries = diaries, error == nil else {
                // 에러 처리...
                return
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z" // 원본 날짜 형식

            let targetFormatter = DateFormatter()
            targetFormatter.dateFormat = "yyyy-MM-dd" // 목표 날짜 형식

            // 선택된 날짜 문자열이 설정되어 있지 않다면, 모든 일기를 로드합니다.
            guard let selectedDateString = self.selectedDateString else {
                self.selectedDiaries = diaries
                DispatchQueue.main.async {
                    self.dailyListCollectionView.reloadData()
                }
                return
            }

            // 선택된 날짜 문자열과 일치하는 일기만 필터링합니다.
            self.selectedDiaries = diaries.filter { diary in
                guard let diaryDate = dateFormatter.date(from: diary.dateString) else {
                    return false
                }
                let formattedDiaryDateString = targetFormatter.string(from: diaryDate)
                return formattedDiaryDateString == selectedDateString
            }

            DispatchQueue.main.async {
                self.dailyListCollectionView.reloadData()
            }
        }
    }
    
    private func updateDateLabel() {
        guard let firstDiary = selectedDiaries.first else {
            dateLabel.text = "No diaries selected"
            return
        }
        // DateFormatter를 사용하여 날짜 형식을 설정합니다.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일" // 날짜 형식은 필요에 따라 조정
        if let date = DateFormatter.yyyyMMddHHmmss.date(from: firstDiary.dateString) {
            dateLabel.text = dateFormatter.string(from: date)
        } else {
            dateLabel.text = "Invalid date"
        }
    }
}

extension CalendarListVC : UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedDiaries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DailyListCell.id, for: indexPath) as? DailyListCell else {
            fatalError("Unable to dequeue JournalCollectionViewCell")
        }
        let diary = selectedDiaries[indexPath.row]
        // 날짜 포맷 변경
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"  // 원본 날짜 형식
        if let date = dateFormatter.date(from: diary.dateString) {
            dateFormatter.dateFormat = "yyyy.MM.dd" // 새로운 날짜 형식
            let formattedDateString = dateFormatter.string(from: date)
        
        
        cell.setDailyListCell(title: diary.title, content: diary.content, weather: diary.weather, emotion: diary.emotion, date: formattedDateString)
        }
        if let imageUrlString = diary.imageURL, let imageUrl = URL(string: imageUrlString) {
            cell.imageView.isHidden = false
            URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                        cell.imageView.image = UIImage(data: data)
                }
            }.resume()
        } else {
            // 이미지 URL이 없을 경우 imageView를 숨김
            cell.imageView.isHidden = true
        }
        return cell
    }
    
    // Cell 선택
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let diary = selectedDiaries[indexPath.row]
        let writeDiaryVC = WriteDiaryVC()
        
        // 선택된 일기 정보를 전달하고, 수정 버튼을 활성화
        writeDiaryVC.showsDiary(with: diary)
        writeDiaryVC.delegate = self
        // 일기 수정 화면으로 전환
        writeDiaryVC.modalPresentationStyle = .automatic
        
        self.present(writeDiaryVC, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    
    
    
    
    // 헤더의 크기 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 15)
    }
    // 셀의 크기 설정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = dailyListCollectionView.bounds.width - 32.0
        let height = dailyListCollectionView.bounds.height / 4.2
        return CGSize(width: width, height: height)
    }
}

extension CalendarListVC : DiaryUpdateDelegate {
    func diaryDidUpdate() {
        fetchUpdateDiaries()
    }
}
