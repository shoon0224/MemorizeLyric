//
//  ViewController.swift
//  MemorizeLyric
//
//  Created by 이상훈 on 2020/07/20.
//  Copyright © 2020 이상훈. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore

class ViewController: UIViewController, AVAudioPlayerDelegate{
    
    let rangeSlider = RangeSlider(frame: CGRect.zero)
    
    var changeState = 0
    
    var audioPlayer : AVAudioPlayer! //audioPlayer : AVAudioPlayer 인스턴스 변수
    var audioFile : URL! // 재생할 오디오의 파일명 변수
    var MAX_VOLUME : Float = 10.0 // 최대 볼륨, 실수형 상수
    var progressTimer : Timer! // 타이머를 위한 변수
    var repeatState = false
    
    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime) //#selector이란 함수는 함수내에서 매개변수로 다른 함수를 호출할때 사용하는 함수
    
    @IBOutlet var btnList: UIButton!
    @IBOutlet var tfLyric: UITextView!
    @IBOutlet var lbCurrentTime: UILabel!
    @IBOutlet var lbEndTime: UILabel!
    @IBOutlet var pvProgressView: UISlider!
    @IBOutlet var aPartTime: UILabel!
    @IBOutlet var bPartTime: UILabel!
    
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
        
        
        
        view.addSubview(rangeSlider)
        rangeSlider.addTarget(self, action: #selector(ViewController.rangeSliderValueChanged(_:)), for: .valueChanged)
        
        
        selectAudioFile() //파일선택 실행
        initplay() //재생 모드 초기화함수 실행
    }
    
    
    
    
    // MARK:- slider 옵션
    override func viewDidLayoutSubviews() {
        let margin: CGFloat = 20.0
        let width = view.bounds.width - 2.0 * margin
        rangeSlider.frame = CGRect(x: margin, y: margin + topLayoutGuide.length + 270,
                                   width: width, height: 31.0) // height은 두꼐
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        
        
        lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime)
        
        if(Float(rangeSlider.lowerValue) >= pvProgressView.value){
            pvProgressView.value = Float(rangeSlider.lowerValue)
            audioPlayer.currentTime = TimeInterval(rangeSlider.lowerValue)// A구간과 같은 지점에서 시작할 때 A구간에서 시작하게 해준다. 없으면 현재실행 slider가 처음부터 시작한다.
            if(changeState == 1){
                audioPlayer.play()
                setPlayButtons(false, pause: true, stop:false)
                changeState = 1
                lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime)
                
            }
        }
        else{
            
        }
        if(Float(rangeSlider.upperValue) <= pvProgressView.value){
            pvProgressView.value = Float(rangeSlider.upperValue)
        }
        aPartTime.text = convertNSTimeInterval12String(rangeSlider.lowerValue)
        bPartTime.text = convertNSTimeInterval12String(rangeSlider.upperValue)
        print("Range slider value changed: (\(rangeSlider.lowerValue) , \(rangeSlider.upperValue))")
        
    }
    
    
    
    
    
    // 파일선택
    func selectAudioFile(){
        audioFile = Bundle.main.url(forResource:"별", withExtension: "mp3")
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
        
        
        rangeSlider.minimumValue = 0
        rangeSlider.maximumValue = audioPlayer.duration
        pvProgressView.value = 0 //프로그레스 뷰(pvProgressView)의 진행 0으로 초기화
        pvProgressView.maximumValue = Float(audioPlayer.duration) //프로그래스 바의 최대 값을 음악 시간으로 잡는다
        
        audioPlayer.delegate = self // audioPlayer의 델리게이트는 self
        audioPlayer.prepareToPlay() // prepareToPlay() 실행
        audioPlayer.volume = soundSlider.value // audioaplayer 볼륨을 슬라이더(soundSlider) 값 1.0으로 초기화
        
        lbEndTime.text = convertNSTimeInterval12String(audioPlayer.duration) //음악 끝시간에 플레이어의 기간을 대입한 함수 값 대입
        lbCurrentTime.text = convertNSTimeInterval12String(0)
        setPlayButtons(true, pause: false, stop: false)
        aPartTime.text = convertNSTimeInterval12String(rangeSlider.lowerValue)
        bPartTime.text = convertNSTimeInterval12String(rangeSlider.upperValue)
        
        //        aPartControl.wraps = false //true시 최대값이 되면 다시 최소값으로 내려감
        //        aPartControl.autorepeat = true //누르고 있으면 반복해서 눌려짐
        
        
    }
    
    // '재생', '일시 정지', '정지' 버튼을 활성화 또는 비활성화하는 함수
    func setPlayButtons(_ play: Bool, pause: Bool, stop:Bool){
        btnPlay.isEnabled = play
        btnStop.isEnabled = stop
        btnPause.isEnabled = pause
    }
    
    // 00:00 형태의 문자열로 변환함
    func convertNSTimeInterval12String(_ time:TimeInterval) -> String {
        let min = Int(time/60) //분단위는 정수 시간에서 time을 60으로 나눈 값
        let sec = Int(time.truncatingRemainder(dividingBy: 60)) //time에서 60으로 나눈 나머지값(truncatingRemainder이 나눈 나머지값을 의미)
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }
    
    // '재생' 버튼을 클릭하였을 때
    @IBAction func btnPlay(_ sender: UIButton) {
        audioPlayer.play() //오디오플레이어 실행
        setPlayButtons(false, pause: true, stop:false) //플레이버튼은 꺼지고 일시정지버튼은 켜진다.
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true) //0.1초마다 반복 실행된다
        changeState = 1
    }
    
    // 0.1초마다 호출되며 재생 시간을 표시함
    @objc func updatePlayTime(){
        lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime) // 재생 시간인 audioPlayer.currentTime을 lblCurrentTime에 나타냄
        pvProgressView.value = Float(audioPlayer.currentTime)
        if(pvProgressView.value >= Float(rangeSlider.upperValue)){
            audioPlayer.pause()
            setPlayButtons(true, pause: false, stop: true)
            changeState = 2
        }
        //        pvProgressView.value = Float(audioPlayer.currentTime) // 프로그레스(Progress View)인 pvProgressPlay의 진행 상황
    }
    
    // '일시 정지' 버튼을 클릭하였을 때
    @IBAction func btnPause(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
        //        changeStatus(status: STATUS_PASUE)
        changeState = 2
    }
    
    
    
    // '정지' 버튼을 클릭하였을 때
    @IBAction func btnStop(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        lbCurrentTime.text = convertNSTimeInterval12String(0)
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // 타이머 무효화
        rangeSlider.lowerValue = 0
        rangeSlider.upperValue = Double(audioPlayer.duration)
        //        pvProgressView.value = 0 //프로그레스 뷰(pvProgressView)의 진행 0으로 초기화
        changeState = 0
        
    }
    
    
    
    
    // 볼륨조절
    @IBAction func soundSlider(_ sender: UISlider) {
        audioPlayer.volume = soundSlider.value
    }
    
    
    // 현재 재생중인 프로그레스 바 슬라이드 함수
    @IBAction func progressSlider(_ sender: UISlider) {
        
        if(pvProgressView.value <= Float(rangeSlider.lowerValue)){
            pvProgressView.value = Float(rangeSlider.lowerValue)
        }
        if(pvProgressView.value >= Float(rangeSlider.upperValue)){
            pvProgressView.value = Float(rangeSlider.upperValue)
        }
        audioPlayer.currentTime = TimeInterval(pvProgressView.value)// 잡아당긴 곳 부터 시작
        lbCurrentTime.text =  convertNSTimeInterval12String(audioPlayer.currentTime)
        if(changeState == 1){
            audioPlayer.play()//슬라이드 하고 놓아도 재생상태 유지
            setPlayButtons(false, pause: true, stop:false)
            changeState = 1
        }
        
        
    }
    
    
    // 재생이 종료되었을 때 호출함
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate() // 타이머 무효화
        setPlayButtons(true, pause: false, stop: false)
    }
    
}

