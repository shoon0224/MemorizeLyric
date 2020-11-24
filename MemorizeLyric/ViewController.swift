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
import MediaPlayer
import Speech
import AVFoundation


class ViewController: UIViewController, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource, SFSpeechRecognizerDelegate{
    
    var audioList:NSArray! //플레이 리스트에 음악 리스트배열
    var currentAudioPath:URL! //재생할 오디오의 파일명 변수
    var currentAudio = ""
    var currentAudioIndex = 0 //현재 음악 인덱스 값 초기화
    let rangeSlider = RangeSlider(frame: CGRect.zero) //구간 슬라이더를 쓰기위한 변수
    var changeState = 0 //재생중인지 일시정지인지 정지상태인지 상태값을 위한 변수
    var audioPlayer : AVAudioPlayer! //audioPlayer : AVAudioPlayer 인스턴스 변수
    var MAX_VOLUME : Float = 10.0 // 최대 볼륨, 실수형 상수
    var progressTimer : Timer! // 타이머를 위한 변수
    var repeatState = false //반복재생 상태 초기화
    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime) //#selector이란 함수는 함수내에서 매개변수로 다른 함수를 호출할때 사용하는 함수
    
    
    
    @IBOutlet var lbSongName: UILabel!
    @IBOutlet var lbArtistName: UILabel!
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
    @IBOutlet var btnRepeat: UIButton!
    @IBOutlet var tableView1: UITableView!
    @IBOutlet var btnAm: UIButton!
    @IBOutlet var btnAp: UIButton!
    @IBOutlet var btnBm: UIButton!
    @IBOutlet var btnBp: UIButton!
    @IBOutlet var btnAddMy: UIButton!
    @IBOutlet var lbGoodBad: UILabel!
    
    
    @IBOutlet weak var transcriptionTextField: UITextView! // stt
    @IBOutlet weak var sttBtn: UIButton! //stt
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        pvProgressView.setThumbImage(UIImage(named: "pin.png"), for: UIControl.State.normal) // 평상시 재생중인 핀 이미지
        pvProgressView.setThumbImage(UIImage(named: "pin.png"), for: UIControl.State.highlighted) //드래그 시 재생중인 핀 이미지
        btnRepeat.setImage(UIImage(named: "repeat.png"), for: UIControl.State.normal) //반복 재생 이미지 기본값
        tableView1.isHidden = true
        view.addSubview(rangeSlider)// 구간 슬라이더 보이기
        rangeSlider.addTarget(self, action: #selector(ViewController.rangeSliderValueChanged(_:)), for: .valueChanged) //구간슬라이더 함수
        soundSlider.value = 1.0 //슬라이더(soundSlider) 볼륨 1.0으로 초기화
        initplay() //재생 모드 초기화함수 실행
        updateLabels() //첫 곡의 제목 가수
        tfLyric.text = "음악을 재생하세요."
    }
    
    //MARK:- STT
    func requestSpeechAuth() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
                if let path = Bundle.main.url(forResource: "test", withExtension: "m4a") {
                    do {
                        let sound = try AVAudioPlayer(contentsOf: path)
                        self.audioPlayer = sound
                        self.audioPlayer.delegate = self
                        sound.play()
                    } catch {
                        print("Error!")
                    }
                    
                    let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
                    let request = SFSpeechURLRecognitionRequest(url: path)
                    recognizer?.recognitionTask(with: request) { (result, error) in
                        if let error = error {
                            print("There was no error: \(error)")
                        } else {
                            self.transcriptionTextField.text = result?.bestTranscription.formattedString
                        }
                    }
                }
            }
        }
    }
    @IBAction func playBtn(_ sender: UIButton) {
        requestSpeechAuth() //기존에 있던 음성녹음파일 재생
        
    }
    
    
    
    // MARK:- 구간 슬라이더 함수
    override func viewDidLayoutSubviews() { //화면에 보일 구간 슬라이더 셋팅값
        let margin: CGFloat = 2.0
        let width = view.bounds.width - 2.0 * margin
        rangeSlider.frame = CGRect(x: margin, y: margin + topLayoutGuide.length + 313,
                                   width: width, height: 31.0) // height은 두꼐
    }
    
    override func didReceiveMemoryWarning() { //메모리 관련 경고 함수
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) { //구간 슬라이드 이벤트
        lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime) // 구간 슬라이드를 잡고 슬라이드 할 시 현재 진행 시간 표시
        if(Float(rangeSlider.lowerValue) >= pvProgressView.value){ //A구간 값이 현재 진행값 보다 같거 나 클경우 조건문
            pvProgressView.value = Float(rangeSlider.lowerValue) //현재 진행값은 A구간 값과 같다.
            audioPlayer.currentTime = TimeInterval(rangeSlider.lowerValue)// A구간과 같은 지점에서 시작할 때 A구간에서 시작하게 해준다. 없으면 현재실행 slider가 처음부터 시작한다.
            if(changeState == 1){ //만약 음악이 재생상태에서 구간 슬라이드를 슬라이드 했을 경우
                audioPlayer.play() //음악을 재생하고
                setPlayButtons(false, pause: true, stop:false) //음악 상태를 다음과 같이 셋팅해주고
                changeState = 1 //음악은 계속 재생상태인 "1"로 유지
                lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime)// 현재 재생중인 텍스트 값은 현재 재생값으로 그대로 대치
            }
        }
        if(Float(rangeSlider.upperValue) <= pvProgressView.value){ // B구간 값이 재생 프로그레스 값보다 작거나 같을 경우 조건문
            pvProgressView.value = Float(rangeSlider.upperValue)// 재생 프로그래스 값은 B구간 슬라이드 값과 같아진다.
        }
        aPartTime.text = convertNSTimeInterval12String(rangeSlider.lowerValue) //A구간 텍스트 값에 현재 A구간 위치 값 대입
        bPartTime.text = convertNSTimeInterval12String(rangeSlider.upperValue) //B구간 텍스트 값에 현재 B구간 위치 값 대입
        print("Range slider value changed: (\(rangeSlider.lowerValue) , \(rangeSlider.upperValue))") //구간 슬라이드 위치 값 콘솔 출력
    }
    
    
    //MARK:- 음악 정보
    // 파일선택
    func selectAudioFile(){ //음악파일이 존재하는 경로를 나타낸다.
        currentAudio = readSongNameFromPlist(currentAudioIndex)
        currentAudioPath = URL(fileURLWithPath: Bundle.main.path(forResource: currentAudio, ofType: "mp3")!)
        print("\(String(describing: currentAudioPath))")
    }
    
    func showMediaInfo(){
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        let songName = readSongNameFromPlist(currentAudioIndex)
        let lyric = readLyric(currentAudioIndex)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist : artistName,  MPMediaItemPropertyTitle : songName,MPMediaItemPropertyLyrics : lyric]
    }
    
    func saveCurrentTrackNumber(){
        UserDefaults.standard.set(currentAudioIndex, forKey:"currentAudioIndex")
        UserDefaults.standard.synchronize()
    }
    
    func readFromPlist(){
        let path = Bundle.main.path(forResource: "list", ofType: "plist")
        audioList = NSArray(contentsOfFile:path!)
    }
    
    func readArtistNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        var infoDict = NSDictionary();
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let artistName = infoDict.value(forKey: "artistName") as! String
        return artistName
    }
    
    func readLyric(_ indexNumber: Int) -> String{
        readFromPlist()
        var lyricDict = NSDictionary();
        lyricDict = audioList.object(at: indexNumber) as! NSDictionary
        let lyric = lyricDict.value(forKey: "lyric") as! String
        return lyric
        
    }
    
    func readSongNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        var songNameDict = NSDictionary();
        songNameDict = audioList.object(at: indexNumber) as! NSDictionary
        let songName = songNameDict.value(forKey: "songName") as! String
        return songName
    }
    
    func retrieveSavedTrackNumber(){
        if let currentAudioIndex_ = UserDefaults.standard.object(forKey: "currentAudioIndex") as? Int{
            currentAudioIndex = currentAudioIndex_
        }else{
            currentAudioIndex = 0
        }
    }
    
    
    func updateLabels(){ //아래 라벨들 최신화
        updateArtistNameLabel()
        updateSongNameLabel()
        updateLyric()
    }
    
    func updateLyric(){ // Textfeild에 가사가 출력되는 부분
        let lyric = readLyric(currentAudioIndex)
        tfLyric.text = lyric
        //        tfLyric.text = ""
    }
    
    func updateArtistNameLabel(){// 아티스트 이름 최신화
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        lbArtistName.text = artistName
    }
    
    func updateSongNameLabel(){ //음악 이름 최신화
        let songName = readSongNameFromPlist(currentAudioIndex)
        lbSongName.text = songName
    }
    
    //MARK:- 기본 셋팅
    //재생 모드의 초기화 셋팅
    func initplay(){
        selectAudioFile() //파일선택 실행 --> 이 소스없으면 다음곡으로 안넘어감(음악정보만 바뀜)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: currentAudioPath)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        soundSlider.maximumValue = MAX_VOLUME // 슬라이더(soundSlider) 최대 볼륨 10.0으로 초기화
        soundSlider.minimumValue = 0 // 최소값을 0으로 지정
        rangeSlider.minimumValue = 0 //구간 슬라이더의 최솟값은 0
        rangeSlider.maximumValue = audioPlayer.duration //구간 슬라이드의 최대값은 음악 재생길이 값과 동일
        rangeSlider.lowerValue = 0
        rangeSlider.upperValue = Double(audioPlayer.duration)
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
        repeatState = false
        updateLabels() //곡 바뀔 때 곡 정보도 바뀜
        
        //        aPartControl.wraps = false //true시 최대값이 되면 다시 최소값으로 내려감
        //        aPartControl.autorepeat = true //누르고 있으면 반복해서 눌려짐
    }
    
    // 00:00 형태의 문자열로 변환함
    func convertNSTimeInterval12String(_ time:TimeInterval) -> String {
        let min = Int(time/60) //분단위는 정수 시간에서 time을 60으로 나눈 값
        let sec = Int(time.truncatingRemainder(dividingBy: 60)) //time에서 60으로 나눈 나머지값(truncatingRemainder이 나눈 나머지값을 의미)
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }
    
    // '재생', '일시 정지', '정지' 버튼을 활성화 또는 비활성화하는 함수
    func setPlayButtons(_ play: Bool, pause: Bool, stop:Bool){
        btnPlay.isEnabled = play
        btnStop.isEnabled = stop
        btnPause.isEnabled = pause
    }
    
    //MARK:- 컨트롤러 함수
    // 0.1초마다 호출되며 재생 시간을 표시함
    @objc func updatePlayTime(){ //어떤 상태이든 0.1초마다 계속 실행되는 함수인걸 명심
        lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime) // 재생 시간인 audioPlayer.currentTime을 lblCurrentTime에 나타냄
        pvProgressView.value = Float(audioPlayer.currentTime)
        if(pvProgressView.value >= Float(rangeSlider.upperValue)){
            pvProgressView.value = Float(rangeSlider.lowerValue)
            audioPlayer.currentTime = rangeSlider.lowerValue
            if(repeatState == true){
                abPartDidFinishPlaying()
            }
            else if (repeatState == false){
                audioPlayer.stop()
                setPlayButtons(true, pause: false, stop: false)
                changeState = 0
            }
        }
        //실시간 가사 편법
        if(pvProgressView.value <= 23){
            tfLyric.text = "널 바라보는 순간이"
        }
        if(pvProgressView.value > 23 && pvProgressView.value <= 32){
            tfLyric.text = "갈수록 길어지는 나를 발견하게 됐을 때"
        }
        if(pvProgressView.value > 32 && pvProgressView.value <= 39){
            tfLyric.text = "두근거려 오는 너와 눈 마주치는 순간"
        }
        if(pvProgressView.value > 39 && pvProgressView.value <= 46){
            tfLyric.text = "피해버리는 내 떨림에"
        }
        if(pvProgressView.value > 46 && pvProgressView.value <= 54){
            tfLyric.text = "나도 놀라서 얼버무리는 내 모습이"
        }
        if(pvProgressView.value > 54 && pvProgressView.value <= 61){
            tfLyric.text = "너에게 보여준 나의 유일한 맘"
        }
        if(pvProgressView.value > 61 && pvProgressView.value <= 65){
            tfLyric.text = "말을 하려 해도"
        }
        if(pvProgressView.value > 65 && pvProgressView.value <= 69){
            tfLyric.text = "막 뒤엉키는 준비한 고백은"
        }
        if(pvProgressView.value > 69 && pvProgressView.value <= 76){
            tfLyric.text = "한 번도 보지 못한 답답한 내 모습"
        }
        if(pvProgressView.value > 76 && pvProgressView.value <= 82){
            tfLyric.text = "널 사랑하기 전 나만 큼만"
        }
        if(pvProgressView.value > 82 && pvProgressView.value <= 91){
            tfLyric.text = "우연히 친구 만날 때처럼 만큼만"
        }
        if(pvProgressView.value > 91 && pvProgressView.value <= 98){
            tfLyric.text = "조금 더 침착 하게 조금 더 솔직하게"
        }
        if(pvProgressView.value > 98 && pvProgressView.value <= 102){
            tfLyric.text = "너 만을 위해"
        }
        if(pvProgressView.value > 102 && pvProgressView.value <= 107){
            tfLyric.text = "꼭 해주고 싶던 말"
        }
        if(pvProgressView.value > 107 && pvProgressView.value <= 110){
            tfLyric.text = "사랑해"
        }
        if(pvProgressView.value > 121 && pvProgressView.value <= 126){
            tfLyric.text = "아무도 몰라"
        }
        if(pvProgressView.value > 126 && pvProgressView.value <= 129){
            tfLyric.text = "나 혼자 많이 고민 했던"
        }
        if(pvProgressView.value > 129 && pvProgressView.value <= 136){
            tfLyric.text = "니 생각 니 걱정 들이 버거워서"
        }
        if(pvProgressView.value > 136 && pvProgressView.value <= 141){
            tfLyric.text = "말을 하려 해도"
        }
        if(pvProgressView.value > 141 && pvProgressView.value <= 145){
            tfLyric.text = "막 뒤엉키는 준비한 고맥은"
        }
        if(pvProgressView.value > 145 && pvProgressView.value <= 151){
            tfLyric.text = "한 번도 보지 못한 답답한 내 모습"
        }
        if(pvProgressView.value > 151 && pvProgressView.value <= 158){
            tfLyric.text = "널 사랑하기 전 나만큼만"
        }
        if(pvProgressView.value > 158 && pvProgressView.value <= 167){
            tfLyric.text = "우연히 친구 만날 때처럼 만큼만"
        }
        if(pvProgressView.value > 167 && pvProgressView.value <= 174){
            tfLyric.text = "조금 더 침착하게 조금 더 솔직하게"
        }
        if(pvProgressView.value > 174 && pvProgressView.value <= 178){
            tfLyric.text = "너 만을 위해"
        }
        if(pvProgressView.value > 174 && pvProgressView.value <= 183){
            tfLyric.text = "꼭 해주고 싶던 말"
        }
        if(pvProgressView.value > 183 && pvProgressView.value <= 184){
            tfLyric.text = "사랑해"
        }
        if(pvProgressView.value > 184 && pvProgressView.value <= 191){
            tfLyric.text = "너의 거절도 생각해 봤지만"
        }
        if(pvProgressView.value > 191 && pvProgressView.value <= 199){
            tfLyric.text = "담아 두기에는 늦은 것 같기에"
        }
        if(pvProgressView.value > 202 && pvProgressView.value <= 208){
            tfLyric.text = "널 사랑하기 전 나 만큼만"
        }
        if(pvProgressView.value > 209 && pvProgressView.value <= 216){
            tfLyric.text = "우연히 친구 만날 때 처럼 만큼만"
        }
        if(pvProgressView.value > 216 && pvProgressView.value <= 220){
            tfLyric.text = "조금더 침착하게"
        }
        if(pvProgressView.value > 220 && pvProgressView.value <= 228){
            tfLyric.text = "조금 더 솔직하게"
        }
        if(pvProgressView.value > 231 && pvProgressView.value <= 234){
            tfLyric.text = "너 만을 위해"
        }
        if(pvProgressView.value > 234 && pvProgressView.value <= 240){
            tfLyric.text = "꼭 해주고 싶던 말"
        }
        if(pvProgressView.value > 241 && pvProgressView.value <= 250){
            tfLyric.text = "사랑해"
        }
        
        
        if(tfLyric.text == transcriptionTextField.text)
        {
            lbGoodBad.text = "좋아요! 잘부르네요"
            
        }
        else if(tfLyric.text != transcriptionTextField.text)
        {
            lbGoodBad.text = "다시 불러봐요.."
            
        }
        //        pvProgressView.value = Float(audioPlayer.currentTime) // 프로그레스(Progress View)인 pvProgressPlay의 진행 상황
    }
    
    // '재생' 버튼을 클릭하였을 때
    @IBAction func btnPlay(_ sender: UIButton) {
        audioPlayer.play() //오디오플레이어 실행
        setPlayButtons(false, pause: true, stop:false) //플레이버튼은 꺼지고 일시정지버튼은 켜진다.
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true) //0.1초마다 반복 실행된다
        changeState = 1
        showMediaInfo()//음악의 정보를 보여준다.
    }
    
    // '일시 정지' 버튼을 클릭하였을 때
    @IBAction func btnPause(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
        //changeStatus(status: STATUS_PASUE)
        changeState = 2
    }
    
    // '정지' 버튼을 클릭하였을 때
    @IBAction func btnStop(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        lbCurrentTime.text = convertNSTimeInterval12String(0)
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // 타이머 무효화
        pvProgressView.value = Float(rangeSlider.lowerValue)
        rangeSlider.lowerValue = 0
        rangeSlider.upperValue = Double(audioPlayer.duration)
        //        pvProgressView.value = 0 //프로그레스 뷰(pvProgressView)의 진행 0으로 초기화
        changeState = 0
        
    }
    
    //next버튼 클릭 이벤트
    @IBAction func btnNext(_ sender: UIButton) {
        currentAudioIndex += 1
        initplay()
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: false)
        if (currentAudioIndex>audioList.count-1){
            currentAudioIndex = 0
        }
        if audioPlayer.isPlaying{
            initplay()
            audioPlayer.play()
            setPlayButtons(false, pause: true, stop: false)
        } else {
            initplay()
        }
    }
    
    //pre 버튼 클릭 이벤트
    @IBAction func btnPrevious(_ sender: UIButton) {
        currentAudioIndex -= 1
        rangeSlider.lowerValue = 0
        initplay()
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: false)
        if currentAudioIndex<0{
            currentAudioIndex += 1
            return
        }
        if audioPlayer.isPlaying{
            initplay()
            audioPlayer.play()
            setPlayButtons(false, pause: true, stop: false)
        }else{
            initplay()
        }
    }
    
    
    
    // 볼륨조절
    @IBAction func soundSlider(_ sender: UISlider) {
        audioPlayer.volume = soundSlider.value
    }
    
    //반복 버튼 클릭 이벤트
    @IBAction func btnRepeat(_ sender: UIButton) {
        if(sender.isSelected == true) {
            sender.isSelected = false
            repeatState = false
            UserDefaults.standard.set(false, forKey: "repeatState")//반복상태를 로컬 저장소에 저장해둔다
            btnRepeat.setImage(UIImage(named: "repeat.png"), for: UIControl.State.normal)
            print("반복 꺼짐")
        } else {
            sender.isSelected = true
            repeatState = true
            UserDefaults.standard.set(true, forKey: "repeatState")
            btnRepeat.setImage(UIImage(named: "repeat_s.png"), for: UIControl.State.normal)
            print("반복 켜짐")
        }
    }
    
    
    
    // 현재 재생중인 프로그레스 바 슬라이드 함수
    @IBAction func progressSlider(_ sender: UISlider) {
        if(pvProgressView.value <= Float(rangeSlider.lowerValue)){
            pvProgressView.value = Float(rangeSlider.lowerValue)
        }
        if(pvProgressView.value >= Float(rangeSlider.upperValue)){
            pvProgressView.value = Float(rangeSlider.upperValue)
        }
        audioPlayer.currentTime = TimeInterval(pvProgressView.value) // 잡아당긴 곳 부터 시작
        lbCurrentTime.text =  convertNSTimeInterval12String(audioPlayer.currentTime)
        if(changeState == 1){
            audioPlayer.play()//슬라이드 하고 놓아도 재생상태 유지
            setPlayButtons(false, pause: true, stop:false)
            changeState = 1
        }
        
    }
    
    @IBAction func btnApartM(_ sender: UIButton) {
        rangeSlider.lowerValue -= 1.0
        aPartTime.text = convertNSTimeInterval12String(rangeSlider.lowerValue)
    }
    @IBAction func btnApartP(_ sender: UIButton) {
        lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime)
        rangeSlider.lowerValue += 1.0
        aPartTime.text = convertNSTimeInterval12String(rangeSlider.lowerValue)
        if(Float(rangeSlider.lowerValue) > pvProgressView.value){ //A구간 값이 현재 진행값 보다 같거 나 클경우 조건문
            pvProgressView.value = Float(rangeSlider.lowerValue) //현재 진행값은 A구간 값과 같다.
            audioPlayer.currentTime = TimeInterval(rangeSlider.lowerValue)// A구간과 같은 지점에서 시작할 때 A구간에서 시작하게 해준다. 없으면 현재실행 slider가 처음부터 시작한다.
        }
        
    }
    @IBAction func btnBpartM(_ sender: UIButton) {
        lbCurrentTime.text = convertNSTimeInterval12String(audioPlayer.currentTime)
        rangeSlider.upperValue -= 1.0
        bPartTime.text = convertNSTimeInterval12String(rangeSlider.upperValue)
        if(Float(rangeSlider.upperValue) < pvProgressView.value){
            pvProgressView.value = Float(rangeSlider.upperValue)
            audioPlayer.currentTime = TimeInterval(rangeSlider.upperValue)
        }
    }
    @IBAction func btnBpartP(_ sender: UIButton) {
        rangeSlider.upperValue += 1.0
        bPartTime.text = convertNSTimeInterval12String(rangeSlider.upperValue)
    }
    
    
    //MARK:- 상태 함수
    // 재생이 완전 종료되었을 때 호출함, 즉(upperValue == audioPlayer.duration 일경우 해당)
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("종료됨 플래그")
        if(flag == true){
            if(repeatState == true){
                if(rangeSlider.lowerValue != 0){
                    pvProgressView.value = Float(rangeSlider.lowerValue)
                    audioPlayer.play()
                    setPlayButtons(false, pause: true, stop: false)
                    changeState = 1
                }
            }
            else if(repeatState == false){
                audioPlayer.stop()
                //                progressTimer.invalidate() // 타이머 무효화
                setPlayButtons(true, pause: false, stop: false)
            }
        }
    }
    
    //구간 반복으로 종료되었을 때
    func abPartDidFinishPlaying(){
        if(repeatState == true){
            pvProgressView.value = Float(rangeSlider.lowerValue)
            audioPlayer.play()
            setPlayButtons(false, pause: true, stop: false)
            changeState = 1
        }
    }
    
    //MARK:- 리스트 관련 Table
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { //리스트 몇개?
        return tableView == tableView1 ? audioList.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        if( tableView == tableView1){
            var songNameDict = NSDictionary(); // NSDictionarty()는 여러 자료를 하나의 딕셔너리에 넣고 원하는 자료를 꺼내오고 싶을 때, 딕셔너리를 생성할 때 부여해준 key를 통해 검색하여 가져온다.
            songNameDict = audioList.object(at: (indexPath as NSIndexPath).row) as! NSDictionary
            let songName = songNameDict.value(forKey: "songName") as! String
            
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "myCell")
            cell.textLabel?.textColor = UIColor.white
            cell.textLabel?.text = songName
            cell.detailTextLabel?.textColor = UIColor.white
            cell.backgroundColor = UIColor.black
            tableView1.backgroundColor = UIColor.black
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { //테이블에서 음악 선택 시 이벤트
        if(tableView == tableView1){
            tableView.deselectRow(at: indexPath, animated: true)
            currentAudioIndex = (indexPath as NSIndexPath).row
            initplay()
            audioPlayer.play() //오디오플레이어 실행
            setPlayButtons(false, pause: true, stop:false) //플레이버튼은 꺼지고 일시정지버튼은 켜진다.
            rangeSlider.lowerValue = 0
            rangeSlider.upperValue = audioPlayer.duration
        }
    }
    
    @IBAction func btnListButton(_ sender: UIButton) {
        if(tableView1.isHidden == true){
            tableView1.isHidden = false
        }
        else if(tableView1.isHidden == false){
            tableView1.isHidden = true
        }
    }
    
    @IBAction func btnAddMyList(_ sender: UIButton) {
        
    }
    
}

