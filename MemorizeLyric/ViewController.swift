//
//  ViewController.swift
//  MemorizeLyric
//
//  Created by 이상훈 on 2020/07/20.
//  Copyright © 2020 이상훈. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate{
    
    // 현재 상태 상수값
    let STATUS_PLAY = 0
    let STATUS_PAUSE = 1
    let STATUS_STOP = 2
    let STATUS_PRE = 3
    let STATIS_NEXT = 4
    
    
    var audioPlayer : AVAudioPlayer! //audioPlayer : AVAudioPlayer 인스턴스 변수
    var audioFile : URL! // 재생할 오디오의 파일명 변수
    var MAX_VOLUME : Float = 10.0 // 최대 볼륨, 실수형 상수
    var progressTimer : Timer! // 타이머를 위한 변수
    
    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime)
    
    @IBOutlet var btBack: UIImageView!
    @IBOutlet var btList: UIButton!
    @IBOutlet var tfLyric: UITextField!
    @IBOutlet var lbCurrentTime: UILabel!
    @IBOutlet var lbEndTime: UILabel!
    @IBOutlet var dragA: UIImageView!
    @IBOutlet var dragB: UIImageView!
    @IBOutlet var pvProgressView: UIProgressView!
    @IBOutlet var dragCurrentPlay: UIImageView!
    @IBOutlet var aPartTime: UILabel!
    @IBOutlet var aPartControl: UIStepper!
    @IBOutlet var bPartTime: UILabel!
    @IBOutlet var bPartControl: UIStepper!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    @IBOutlet var btnPre: UIButton!
    @IBOutlet var soundSlider: UISlider!
    @IBOutlet var btRandom: UIImageView!
    @IBOutlet var btLoop: UIImageView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        selectAudioFile()
        initplay()
    }
    
    // 파일선택
    func selectAudioFile(){
        audioFile = Bundle.main.url(forResource:"test", withExtension: "mp3")
    }
    
    //재생 모드의 초기화
    func initplay(){
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        soundSlider.maximumValue = MAX_VOLUME // 슬라이더(soundSlider) 최대 볼륨 10.0으로 초기화
        soundSlider.value = 1.0 //슬라이더(soundSlider) 볼륨 1.0으로 초기화
        pvProgressView.progress = 0 //프로그레스 뷰(pvProgressView)의 진행 0으로 초기화
        
        audioPlayer.delegate = self // audioPlayer의 델리게이트는 self
        audioPlayer.prepareToPlay() // prepareToPlay() 실행
        audioPlayer.volume = soundSlider.value // audioaplayer 볼륨을 슬라이더(soundSlider) 값 1.0으로 초기화
        
        lbEndTime.text = convertNSTimeInterval12String(audioPlayer.duration)
        lbCurrentTime.text = convertNSTimeInterval12String(0)
        setPlayButtons(true, pause: false, stop: false)
    }
    
    // '재생', '일시 정지', '정지' 버튼을 활성화 또는 비활성화하는 함수
    func setPlayButtons(_ play: Bool, pause: Bool, stop:Bool){
        btnPlay.isEnabled = play
        btnStop.isEnabled = stop
        btnPause.isEnabled = pause
    }
    
    // 00:00 형태의 문자열로 변환함
    func convertNSTimeInterval12String(_ time:TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }
    
    // '재생' 버튼을 클릭하였을 때
    
    @IBAction func btnPlay(_ sender: UIButton) {
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop:false)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    // 0.1초마다 호출되며 재생 시간을 표시함
    @objc func updatePlayTime(){
        lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime) // 재생 시간인 audioPlayer.currentTime을 lblCurrentTime에 나타냄
        pvProgressView.progress = Float(audioPlayer.currentTime/audioPlayer.duration) // 프로그레스(Progress View)인 pvProgressPlay의 진행 상황에 audioPlayer.currentTime을 audioPlayer.duration으로 나눈 값으로 표시
    }
    
    // '일시 정지' 버튼을 클릭하였을 때
    
    @IBAction func btnPause(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
//        changeStatus(status: STATUS_PASUE)
    }
    
    
    
    // '정지' 버튼을 클릭하였을 때
    
    @IBAction func btnStop(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        lbCurrentTime.text = convertNSTimeInterval12String(0)
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // 타이머 무효화
//        changeStatus(status: STATUS_STOP)
    }
    
    
    
    
    // 볼륨 슬라이더 값을 audioplayer.volume에 대임함
    
    @IBAction func soundSlider(_ sender: UISlider) {
        audioPlayer.volume = soundSlider.value
    }
    
    
    
    // 재생이 종료되었을 때 호출함
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate() // 타이머 무효화
        setPlayButtons(true, pause: false, stop: false)
    }
    
}

