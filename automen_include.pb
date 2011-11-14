
; PureBasic Visual Designer v3.95 build 1485 (PB4Code)

Global ver.s

Enumeration
  #Window_0
EndEnumeration


;
Enumeration
  #open
  #speedqualitytext
  #save
  #ffmpeg
  #multithread
  #resizer
  #inputstring
  #outputstring
  #preview
  #play
  #Panel_0
  #container
  #extsub
  #basicfile
  #videocodec
  #videokbits
  #videolenght
  #cds
  #vframes
  #trackwidth
  #height
  #width
  #topcrop
  #bottomcrop
  #rightcrop
  #leftcrop
  #arcombo
  #autocrop
  #audibit
  #sampling
  #shutdown
  #channel
  #audiotrack
  #audionormalize
  
  #denoise
  #allowresize
  #audiocodec
  #pass
  #Panel_2
  #encode
  #muxvideotrackbtt
  #muxvideotrack
  #muxaudiotrackbtt
  #muxaudiotrack1
  #muxaudiotrack2btt
  #muxaudiotrack2
  #framerate
  #anamorphic
  #dar
  #demuxinputbutton
  #demuxinputfile
  #demuxpathbutton
  #demuxpathtext
  #whatdemux
  #startdemux
  #muxtype
  #fixbutton
  #filetofix
  #outputbuttonfix
  #filefixed
  #startfix
  #addtoqueue
  #removequeuejob
  #modheight
  #itu
  #mdeint
  #modwidth
  #startqueue
  #arerror
  #queue
  #startmux
  #speedquality
  #mp3mode
  #Text_32
  #Text_33
  #paypal
  #noodml
  #nosubs
  #ffourcc
  #buttontomencoder
  #ffmpegpipe
  #buttontomkvmerge
  #buttontomp4box
  #buttontomplayer
  #pathtomencoder
  #pathtomkvmerge
  #widthf
  #heightf
  #framecountf
  #frameratef
  #pathtomp4box
  #addedtoqueue
  #encodewith
  #pathtomplayer
  #Window_1
  #subs
  #pgcaccept
  #buttonffmpeg
  #pathtoffmpeg
  #Text_122
  #pgc
  #savesetting
  #text50
  #text51
  #makereport
  #buttonaddtoqueue
  #nocrop
  #statusbar
  
  #clean
EndEnumeration



#PROCESS32LIB = 9999
#PSAPI = 9998

Enumeration
  #StatusBar_0
EndEnumeration

;UsePNGImageDecoder()

UseJPEGImageDecoder()

Global Image0,FontID1,comboheight.l

CompilerIf #PB_Compiler_OS = #PB_OS_Linux :  comboheight.l=25 : ver.s="v7.0": CompilerEndIf
CompilerIf #PB_Compiler_OS = #PB_OS_Windows : comboheight.l=20 : ver.s="v7."+Str(#pb_editor_compilecount)+"."+Str(#pb_editor_buildcount): CompilerEndIf

Image0 = CatchImage(#paypal, ?Image0)

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  If LoadFont(1,GetCurrentDirectory()+"DejaVuSansMono.ttf", 8)
    SetGadgetFont(#PB_Default,FontID(1))
  Else
    LoadFont(1,"Arial", 8)
    SetGadgetFont(#PB_Default,FontID(1))
  EndIf
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
  If LoadFont(1,"DejaVuSansCondensed", 8)
    SetGadgetFont(#PB_Default,FontID(1))
  Else
    LoadFont(1,"Arial", 7)
    SetGadgetFont(#PB_Default,FontID(1))
  EndIf
CompilerEndIf


DataSection
  Image0: IncludeBinary "_paypal_logo.jpg"
EndDataSection


Procedure Open_Window_1()
  If OpenWindow(#Window_1, 216, 0, 507, 85, "Select PGC and click Accept PGC",  #PB_Window_SystemMenu | PB_Window_TitleBar )
    
    ButtonGadget(#pgcaccept,380,10,120,20,"Accept PGC")
    ComboBoxGadget(#pgc, 100, 10, 270, 20)
    TextGadget(#Text_122, 10, 10, 80, 20, "Select PGC", #PB_Text_Center | #PB_Text_Border)
    
    
  EndIf
EndProcedure


Procedure Open_Window_0()
  If OpenWindow(#Window_0, 336, 289, 520, 430, "AutoMen "+ver.s,  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_TitleBar|#PB_Window_ScreenCentered)
    
    CreateStatusBar(#statusbar,WindowID(#Window_0))
    AddStatusBarField(#PB_Ignore)
    
    ButtonGadget(#open, 20, 40, 70, comboheight, "Open ...")
    ButtonGadget(#save, 20, 70, 70, comboheight, "Save ...")
    StringGadget(#inputstring, 100, 40, 300, comboheight, "")
    StringGadget(#outputstring, 100, 70, 300, comboheight, "")
    
    Frame3DGadget(#PB_Any, 20, 100, 480, 270, "")
    TextGadget(#PB_Any, 20, 10, 340, 20, " 1. Open File, 2. Select Encoding Mode , 3. Encode")
    
    ButtonGadget(#play, 410, 10, 90, comboheight, "Play")
    ButtonGadget(#encode, 410, 40, 90, comboheight, "Encode")
    ButtonGadget(#preview, 410, 70, 90, comboheight, "Preview")
    ImageGadget(#paypal, 20, 378, 85, 25, Image0)
    TextGadget(#PB_Any,125,380,375,20,"Buzzqw's Mencoder GUI",#PB_Text_Border|#PB_Text_Center)
    
    
    ;- main panel
    PanelGadget(#Panel_0, 30, 120, 460, 240)
      AddGadgetItem(#Panel_0, -1, "Summary")
      
      Frame3DGadget(#PB_Any, 8, 3, 215, 205, "Source Format")
      TextGadget(#PB_Any,20,28,90,20,"Width/Height") : StringGadget(#widthf,110,25,50,20,"") :  StringGadget(#heightf,165,25,50,20,"")
      TextGadget(#PB_Any,20,53,85,20,"FPS/Num Frames") : StringGadget(#frameratef,110,50,50,20,"") : StringGadget(#framecountf,165,50,50,20,"")
      
      EditorGadget(#basicfile, 20,80, 195,120)
      
      
      Frame3DGadget(#PB_Any, 233, 3, 218, 123, "Target Format")
      TextGadget(#PB_Any,245,28,80,25,"Encode with")
      ComboBoxGadget(#videocodec, 315, 25,65,comboheight )
      AddGadgetItem(#videocodec,-1,"XviD")
      AddGadgetItem(#videocodec,-1,"Mpeg4")
      AddGadgetItem(#videocodec,-1,"X264")
      SetGadgetState(#videocodec,0)
      
      ComboBoxGadget(#container,385,25,60,comboheight.l)
      SetGadgetState(#container,0)
      
      TextGadget(#PB_Any,245,53,60,20,"Pass to do")
      ComboBoxGadget(#pass, 315, 50,130,comboheight )
      
      TextGadget(#PB_Any,245,81,60,20,"Preset")
      TrackBarGadget(#speedquality,308,75,140,17,1,10,#PB_TrackBar_Ticks)
      StringGadget(#speedqualitytext,245,95,200,comboheight,"",#PB_String_ReadOnly|#PB_Text_Center)
      
      Frame3DGadget(#PB_Any, 233, 127, 218, 80, "Video Options")
      TextGadget(#Text_32, 245, 145, 70, 20, "Video Bitrate:")
      StringGadget(#videokbits, 320, 145, 60, comboheight, "")
      TextGadget(#Text_33, 385,149, 40, comboheight, "kbit/s")
      
      StringGadget(#videolenght, 245, 170, 40, comboheight, "",#PB_String_ReadOnly)
      TextGadget(#PB_Any, 290, 173, 80, comboheight, "minutes keep in:")
      StringGadget(#cds,375,170,40,comboheight,"700",#PB_String_Numeric)
      TextGadget(#PB_Any,420,173,20,comboheight,"MB")
      
     
      ;-panel video
      AddGadgetItem(#Panel_0, -1, "Video")
      
      
      Frame3DGadget(#PB_Any, 8, 8, 440, 200, "Resizing Options")
      
      CheckBoxGadget(#allowresize, 18, 25, 95, 20, "Allow Resize")
      SetGadgetState(#allowresize,1)
      
      TextGadget(#PB_Any, 163, 25, 60, 20, " DAR:" ,#PB_Text_Center)
      StringGadget(#dar, 223, 25, 60, comboheight ,"",#PB_String_ReadOnly)
      
      ButtonGadget(#autocrop, 318, 25, 120, comboheight, " Do AutoCrop",#PB_Button_Left)
      
      TextGadget(#PB_Any, 242,50, 67, 20, "Frame Pattern")
      ComboBoxGadget(#mdeint, 318, 50 ,120, comboheight)
      AddGadgetItem(#mdeint,-1,"Progressive")
      AddGadgetItem(#mdeint,-1,"FILM NTSC (29.97->23.976)")
      AddGadgetItem(#mdeint,-1,"Interlaced")
      AddGadgetItem(#mdeint,-1,"Telecine")
      AddGadgetItem(#mdeint,-1,"Mixed Prog/Telecine")
      AddGadgetItem(#mdeint,-1,"Mixed Prog/Interlaced")
      AddGadgetItem(#mdeint,-1,"Change FPS to 23.976")
      AddGadgetItem(#mdeint,-1,"Change FPS to 25")
      AddGadgetItem(#mdeint,-1,"Change FPS to 29.97")
      SetGadgetState(#mdeint,0)
      
      TextGadget(#PB_Any, 242,75, 85, 20, "Aspect Ratio")
      ComboBoxGadget(#arcombo, 318, 75, 120, comboheight,#PB_ComboBox_Editable)
      AddGadgetItem(#arcombo,-1,"1")
      AddGadgetItem(#arcombo,-1,"1.3334")
      AddGadgetItem(#arcombo,-1,"1.7778")
      AddGadgetItem(#arcombo,-1,"1.85")
      AddGadgetItem(#arcombo,-1,"2.35")
      
      CheckBoxGadget(#anamorphic, 318, 100,115,20,"Anamorphic Resiz.")
      CheckBoxGadget(#itu, 318, 120,120,20,"Follow ITU Resizing")
      SetGadgetState(#itu,0)
      
      TextGadget(#PB_Any, 18, 53, 75, 20, "Top Crop ---->")
      StringGadget(#topcrop, 95, 53, 60, comboheight, "")
      StringGadget(#leftcrop, 18, 78, 60, comboheight, "")
      TextGadget(#PB_Any, 90, 82, 73, 20, "<-Left | Right->")
      StringGadget(#rightcrop, 173, 78, 60, comboheight, "")
      TextGadget(#PB_Any, 18, 103, 90, 20, "Bottom Crop ->")
      StringGadget(#bottomcrop, 95, 103, 60, comboheight, "")
      TextGadget(#PB_Any, 163, 108, 60, 20, " AR Error:" ,#PB_Text_Center)
      StringGadget(#arerror, 223, 103, 60, comboheight, "",#PB_String_ReadOnly)
      
      TrackBarGadget(#trackwidth, 13,130,275, 17, 0, 360)
      
      TextGadget(#PB_Any,18,153,145,20,"Manually Set Width x Height:")
      StringGadget(#width, 160, 150,50, comboheight, "")
      TextGadget(#PB_Any, 223, 153, 10, 20, "x")
      StringGadget(#height, 238, 150, 50, comboheight, "")
      
      TextGadget(#PB_Any,18,183,155,20,"Set MOD block Width x Height:")
      ComboBoxGadget(#modwidth,168,180,50,comboheight)
      AddGadgetItem(#modwidth,-1,"16")
      AddGadgetItem(#modwidth,-1,"8")
      AddGadgetItem(#modwidth,-1,"4")
      SetGadgetText(#modwidth,"4")
      TextGadget(#PB_Any, 223, 183, 10, 20, "x")
      ComboBoxGadget(#modheight,238,180,50,comboheight)
      AddGadgetItem(#modheight,-1,"16")
      AddGadgetItem(#modheight,-1,"8")
      AddGadgetItem(#modheight,-1,"4")
      SetGadgetText(#modheight,"16")
      
      ;-audio panel
      AddGadgetItem(#Panel_0, -1, "Audio")
      Frame3DGadget(#PB_Any, 8, 35, 220, 140, "Audio Parameters")
      Frame3DGadget(#PB_Any, 238,10, 210,50, "Audio Options")
      Frame3DGadget(#PB_Any, 238,70, 210,50, "Subtitle Track")
      ComboBoxGadget(#subs, 247, 90, 175,comboheight)
      ButtonGadget(#extsub,425,90,20,20,"...")
      
      TextGadget(#text50, 18, 58, 70, 20, "Audio Bitrate:")
      ComboBoxGadget(#audibit, 98, 55, 70, comboheight,#PB_ComboBox_Editable)
      AddGadgetItem(#audibit,-1,"320")
      AddGadgetItem(#audibit,-1,"288")
      AddGadgetItem(#audibit,-1,"256")
      AddGadgetItem(#audibit,-1,"224")
      AddGadgetItem(#audibit,-1,"192")
      AddGadgetItem(#audibit,-1,"160")
      AddGadgetItem(#audibit,-1,"128")
      AddGadgetItem(#audibit,-1,"96")
      AddGadgetItem(#audibit,-1,"64")
      SetGadgetState(#audibit,6)
      TextGadget(#text51, 178, 55, 40, 20, "kbit/s")
      TextGadget(#PB_Any, 18, 88, 70, 20, "Sampling:")
      ComboBoxGadget(#sampling, 98, 85, 70, comboheight,#PB_ComboBox_Editable)
      AddGadgetItem(#sampling,-1,"AUTO")
      AddGadgetItem(#sampling,-1,"48000")
      AddGadgetItem(#sampling,-1,"44100")
      AddGadgetItem(#sampling,-1,"22050")
      SetGadgetState(#sampling,0)
      TextGadget(#PB_Any, 178, 85, 40, 20, "hz")
      TextGadget(#PB_Any, 178, 143, 45, 20, "for MP3")
      TextGadget(#PB_Any, 18, 113, 70, 20, "Channels")
      ComboBoxGadget(#channel, 98, 110, 70, comboheight)
      AddGadgetItem(#channel,-1,"Original")
      AddGadgetItem(#channel,-1,"2")
      AddGadgetItem(#channel,-1,"1")
      SetGadgetState(#channel,1)
      
      TextGadget(#PB_Any, 18, 143, 70, 20, "Bitrate Mode")
      ComboBoxGadget(#mp3mode,98,140,70,comboheight)
      AddGadgetItem(#mp3mode,-1,"cbr")
      AddGadgetItem(#mp3mode,-1,"abr")
      SetGadgetState(#mp3mode,0)
      
      CheckBoxGadget(#audionormalize, 248, 33, 150, 20, "Normalize Audio Track")
      SetGadgetState(#audionormalize,1)
      
      TextGadget(#PB_Any, 15, 188, 70, 20, "Audio track:")
      ComboBoxGadget(#audiotrack, 85, 183, 363, comboheight)
      AddGadgetItem(#audiotrack,-1,"none")
      SetGadgetState(#audiotrack,0)
      
      TextGadget(#PB_Any, 10, 13, 80, 20, "Audio Codec:")
      
      ComboBoxGadget(#audiocodec, 98, 12,130,comboheight )
      AddGadgetItem(#audiocodec,-1,"Copy Audio")
      AddGadgetItem(#audiocodec,-1,"No Audio")
      SetGadgetState(#audiocodec,0)
      
      ;-filters panel
      AddGadgetItem(#Panel_0, -1, "Filters")
      TextGadget(#PB_Any,18, 20, 80, 20, "Denoise Level")
      ComboBoxGadget(#denoise, 105,18,110,comboheight)
      AddGadgetItem(#denoise,-1,"NONE")
      AddGadgetItem(#denoise,-1,"Super Light")
      AddGadgetItem(#denoise,-1,"Light")
      AddGadgetItem(#denoise,-1,"Normal")
      AddGadgetItem(#denoise,-1,"Severe")
      SetGadgetState(#denoise,1)
      
      TextGadget(#PB_Any,18, 50, 80, 20, "Select Resizer")
      ComboBoxGadget(#resizer, 105,48,110,comboheight)
      AddGadgetItem(#resizer,-1,"0 bilinear")
      AddGadgetItem(#resizer,-1,"1 bilinear")
      AddGadgetItem(#resizer,-1,"2 bicubic")
      AddGadgetItem(#resizer,-1,"3 experimental")
      AddGadgetItem(#resizer,-1,"4 point")
      AddGadgetItem(#resizer,-1,"5 area")
      AddGadgetItem(#resizer,-1,"6 bicublin")
      AddGadgetItem(#resizer,-1,"7 gauss")
      AddGadgetItem(#resizer,-1,"8 sinc")
      AddGadgetItem(#resizer,-1,"9 lanczos")
      AddGadgetItem(#resizer,-1,"10 spline")
      SetGadgetState(#resizer,2)
      
      TextGadget(#PB_Any,18, 80, 80, 20, "Select Encoder")
      ComboBoxGadget(#encodewith,105,78,210,comboheight)
      SetGadgetState(#encodewith,0)
      
      
      CheckBoxGadget(#nocrop,18,105,195,20,"Don't do automatic crop on input file")
      CheckBoxGadget(#noodml,18,130,185,20,"Don't use ODML")
      CheckBoxGadget(#clean,18,155,225,20,"Clean temp file at end of encoding")
      
      CheckBoxGadget(#multithread,248,130,185,20,"Don't use multithread encoding")
      CheckBoxGadget(#ffourcc,248,155,185,20,"FourCC DIVX for XviD encoding")
      
      CheckBoxGadget(#shutdown,18,180,185,20,"Shutdown at end of encoding")
      ButtonGadget(#makereport,248,180,185,comboheight,"Make Report (needed for support)")
      
      ;-queue
      AddGadgetItem(#Panel_0, -1, "Queue")
      Frame3DGadget(#PB_Any, 8,5, 440, 200, "Queue")
      EditorGadget(#queue,18,28,415,140)
      ButtonGadget(#addtoqueue,18,180,90,comboheight,"Add to Queue")
      ButtonGadget(#removequeuejob,125,180,110,comboheight,"Remove job line")
      ButtonGadget(#startqueue,255,180,80,comboheight,"Start Queue")
      ButtonGadget(#buttonaddtoqueue,340,180,40,comboheight,"add ...")
      ComboBoxGadget(#addedtoqueue,385,180,65,comboheight,#PB_ComboBox_Editable)
      CompilerIf #PB_Compiler_OS = #PB_OS_Linux :  AddGadgetItem(#addedtoqueue,-1,"read") : CompilerEndIf
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows :  AddGadgetItem(#addedtoqueue,-1,"pause") : CompilerEndIf
      AddGadgetItem(#addedtoqueue,-1,"shutdown")
      AddGadgetItem(#addedtoqueue,-1,"Edit Me...")
      SetGadgetState(#addedtoqueue,0)
      
    CloseGadgetList()
    
    ;GadgetToolTip(#play,"Press this button for playing input file")
    
    GadgetToolTip(#nocrop,"This option can be very usefull on file when autocrop is very slow. Usually TS or HD files. If you don't need autocrop.. use this option for a quicker analysis")
    GadgetToolTip(#makereport,"Encoding doesn't work ? Use the Make Report and post on forum/mail me the Report. Without Report i cannot help")
    GadgetToolTip(#encodewith,"Select decoder/encoder. Every encoder has pro and cons and can encode with different codecs")
    GadgetToolTip(#videolenght,"Lenght of movie (in minutes)")
    GadgetToolTip(#basicfile,"Summary information about file to encode")
    GadgetToolTip(#extsub,"Browse for external subtitle. This subs will be hardcodec in video. Option avaiable only for mencoder and avisynth x264")
    GadgetToolTip(#addedtoqueue,"Select what add as last command in queue. You can edit this list")
    GadgetToolTip(#buttonaddtoqueue,"Click here for adding to queue, as bottom line, the command written at right")
    GadgetToolTip(#multithread,"Check this button for disabling multithread encoding. Useful when mencoder crash unexpectly (only for mencoder and ffmpeg)")
    GadgetToolTip(#subs,"This subs will be burnt in video. Option avaiable only when encoding with Mencoder")
    GadgetToolTip(#speedquality,"Select the quality/speed trade-off. Left for faster encoding. Right for slower encoding")
    GadgetToolTip(#framecountf,"This is the number of frames detected by Mplayer. Feel free to change it if wrong (otherwise bitrate will be wrong)")
    GadgetToolTip(#frameratef,"This is the frame rate (fps) detected by Mplayer. Feel free to change it if wrong")
    GadgetToolTip(#widthf,"This is the WIDTH detected by Mplayer. Feel free to change it if wrong")
    GadgetToolTip(#heightf,"This is the HEIGHT detected by Mplayer. Feel free to change it if wrong")
    GadgetToolTip(#play,"Press this button for playing input file (as is, without resize)")
    GadgetToolTip(#encode,"Click here for start encoding!")
    GadgetToolTip(#preview,"Click here for a preview resized")
    GadgetToolTip(#open,"Click here for selecting input file")
    GadgetToolTip(#outputstring,"Select output file")
    GadgetToolTip(#save,"Click here for selecting output file name")
    GadgetToolTip(#videocodec,"Select video codec to use")
    GadgetToolTip(#container,"Select container to use. For MP4 or MKV you need installed MP4Box and MKVToolnix")
    GadgetToolTip(#pass,"Select number of pass/type of encoding")
    GadgetToolTip(#videokbits,"This is the bitrate video. You can manually edit it. AutoMen will use this value")
    GadgetToolTip(#cds,"Write here the final size in MB")
    GadgetToolTip(#allowresize,"Check this for allow resize. Otherwise no resize or crop is applyed")
    GadgetToolTip(#dar,"This is the final dar of movie")
    GadgetToolTip(#topcrop,"How many pixel to crop from top")
    GadgetToolTip(#rightcrop,"How many pixel to crop from right")
    GadgetToolTip(#bottomcrop,"How many pixel to crop from bottom")
    GadgetToolTip(#leftcrop,"How many pixel to crop from left")
    GadgetToolTip(#arerror,"This is the distortion caused by crop and resize")
    GadgetToolTip(#trackwidth,"Move this slider for selecting resolution")
    GadgetToolTip(#modwidth,"This is modulo width must obey")
    GadgetToolTip(#modheight,"This is modulo height must obey")
    GadgetToolTip(#width,"This is the final width of encoding")
    GadgetToolTip(#height,"This is the final height of encoding")
    GadgetToolTip(#autocrop,"Click here for a more deeply (and slower) automatic crop of movie. You need mplayer")
    GadgetToolTip(#arcombo,"Aspect Ratio of movie")
    GadgetToolTip(#mdeint,"Set if input is interlaced")
    GadgetToolTip(#anamorphic,"Apply anamorphic resizing")
    GadgetToolTip(#itu,"Follow ITU resizing rule")
    GadgetToolTip(#mp3mode,"Set kind of LAME encoding. Constant BitRate or Average BitRate")
    GadgetToolTip(#denoise,"Set denoise level")
    GadgetToolTip(#resizer,"Set resizer to use")
    GadgetToolTip(#shutdown,"Force shutdown of pc at end of encoding")
    GadgetToolTip(#noodml,"Force no use of Open DML AVI type (only for Mencoder)")
    GadgetToolTip(#ffourcc,"Force DIVX CC (only with Mencoder)")
    GadgetToolTip(#audiocodec,"This is the codec audio to apply")
    GadgetToolTip(#audibit,"Bitrate of audio")
    GadgetToolTip(#sampling,"Sampling of audio. Do attention")
    GadgetToolTip(#channel,"Number of channels to output")
    GadgetToolTip(#audiotrack,"Select the audio track")
    GadgetToolTip(#audionormalize,"Normalize the volume")
    GadgetToolTip(#addtoqueue,"Add the current work to queue")
    GadgetToolTip(#removequeuejob,"Remove the first line from queue")
    GadgetToolTip(#startqueue,"Start all queued jobs")
    
    
  EndIf
EndProcedure

Procedure.f RoundByClosest(base.f, factor.l)
  round = Int((base / factor)+0.5) * factor
  ProcedureReturn round
EndProcedure

Procedure.f RoundUpBy(base.f, factor.l)
  round = Int((base / factor)+1) * factor
  ProcedureReturn round
EndProcedure

Procedure.f RoundDownBy(base.f, factor.l)
  round = Int(base / factor) * factor
  ProcedureReturn round
EndProcedure

Procedure.l RoundByX(base.f, factor.l, bool_roundup.l)
  If bool_roundup = #True  : ProcedureReturn Round((base / factor),1) * factor
  ElseIf bool_roundup = #False : ProcedureReturn Round((base / factor),0) * factor
EndIf
EndProcedure


; IDE Options = PureBasic 4.41 (Windows - x86)
; CursorPosition = 4
; FirstLine = 4
; Folding = --
; EnableXP
; EnableUser
; DisableDebugger
; EnableCompileCount = 61
; EnableBuildCount = 10
; EnableExeConstant
; IDE Options = PureBasic 4.60 RC 2 (Linux - x64)
; CursorPosition = 440
; FirstLine = 437
; Folding = --
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 4.60 RC 2 (Linux - x64)
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant