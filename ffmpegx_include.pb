
; PureBasic Visual Designer v3.95 build 1485 (PB4Code)


;- Window Constants

Global ver.s

ver.s="v0.9."+Str(#pb_editor_buildcount)+"."+Str(#pb_editor_compilecount)
;
Enumeration
  #Window_0
EndEnumeration

;- Gadget Constants
;
Enumeration
  #open
  #save
  #inputstring
  #outputstring
  #preview
  #play
  #Panel_0
  #basicfile
  #presetsummary
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
  #channel
  #audiotrack
  #audionormalize
  #audiogain
  #deinterlace
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
  #speedbar
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
  #modwidth
  #startqueue
  #addedtoqueue
  #buttonaddtoqueue
  #arerror
  #queue
  #startmux
  #speedqualitytext
  #Text_32
  #Text_33
  #paypal
EndEnumeration

;- StatusBar Constants

#PROCESS32LIB = 9999
#PSAPI = 9998

Enumeration
  #StatusBar_0
EndEnumeration

UsePNGImageDecoder()

Global Image0,FontID1,comboheight.l

If OSVersion()<=#PB_OS_Linux_Future
  comboheight.l=25
EndIf
If OSVersion()<=#PB_OS_Windows_Future
  comboheight.l=20
EndIf

Image0 = CatchImage(#paypal, ?Image0)

If LoadFont(1,GetCurrentDirectory()+"DejaVuSansMono.ttf", 8)
  SetGadgetFont(#PB_Default,FontID(1))
Else
  LoadFont(1,"Arial", 8)
  SetGadgetFont(#PB_Default,FontID(1))
EndIf


DataSection
  Image0: IncludeBinary "_paypal_logo.png"
EndDataSection


Procedure Open_Window_0()
  If OpenWindow(#Window_0, 336, 289, 520, 399, "AutoFFmpeg "+ver.s,  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_TitleBar|#PB_Window_ScreenCentered)
    If CreateStatusBar(#StatusBar_0, WindowID(#Window_0))
    EndIf
    
    ButtonGadget(#open, 20, 40, 70, comboheight, "Open ...")
    ButtonGadget(#save, 20, 70, 70, comboheight, "Save ...")
    StringGadget(#inputstring, 100, 40, 300, comboheight, "")
    StringGadget(#outputstring, 100, 70, 300, comboheight, "")
    
    Frame3DGadget(#PB_Any, 20, 100, 480, 270, "")
    TextGadget(#PB_Any, 20, 10, 350, 20, " 1. Open File, 2. Select a Target format or use tabs, 3. Encode")
    ButtonGadget(#play, 410, 10, 90, comboheight, "Play")
    ButtonGadget(#encode, 410, 40, 90, comboheight, "Encode")
    ButtonGadget(#preview, 410, 70, 90, comboheight, "Preview")
    
    ;- Panel0
    PanelGadget(#Panel_0, 30, 120, 460, 240)
      AddGadgetItem(#Panel_0, -1, "Summary")
      
      Frame3DGadget(#PB_Any, 8, 3, 215, 197, "Source Format")
      TextGadget(#basicfile, 15,20, 200,143, "", #PB_Text_Border)
      
      Frame3DGadget(#PB_Any, 233, 3, 218, 127, "Target Format")
      TextGadget(#PB_Any,245,23,60,25,"Codec")
      ComboBoxGadget(#presetsummary, 315, 25,130,comboheight )
      SetGadgetState(#presetsummary,0)
      
      TextGadget(#PB_Any,245,75,60,25,"Preset")
      TrackBarGadget(#speedbar,310,75,140,17,1,10,#PB_TrackBar_Ticks)
      StringGadget(#speedqualitytext,245,100,200,20,"",#PB_String_ReadOnly|#PB_Text_Center)
      
      
      TextGadget(#PB_Any,245,53,60,20,"Pass to do")
      ComboBoxGadget(#pass, 315, 50,130,comboheight )
      AddGadgetItem(#pass,-1,"1 pass")
      AddGadgetItem(#pass,-1,"2 pass")
      AddGadgetItem(#pass,-1,"CRF 1 pass")
      AddGadgetItem(#pass,-1,"SameQ")
      AddGadgetItem(#pass,-1,"Copy Video")
      SetGadgetState(#pass,0)
      
      Frame3DGadget(#PB_Any, 233, 130, 218, 70, "Video Options")
      TextGadget(#Text_32, 245, 145, 70, 20, "Video Bitrate:")
      StringGadget(#videokbits, 320, 145, 60, 20, "")
      TextGadget(#Text_33, 385,149, 40, 20, "kbit/s")
      
      StringGadget(#videolenght, 245, 170, 40, 20, "")
      TextGadget(#PB_Any, 290, 173, 80, 20, "minutes keep in:")
      StringGadget(#cds,375,170,40,20,"700",#PB_String_Numeric)
      TextGadget(#PB_Any,420,173,20,20,"MB")
      
      
      ImageGadget(#paypal, 16 , 168, 85, 25, Image0)
      
      ;- panel video
      AddGadgetItem(#Panel_0, -1, "Video")
      
      
      Frame3DGadget(#PB_Any, 8, 8, 440, 200, "Resizing Options")
      
      CheckBoxGadget(#allowresize, 18, 25, 95, 20, "Allow Resize")
      SetGadgetState(#allowresize,1)
      
      TextGadget(#PB_Any, 163, 25, 60, 20, " DAR:" ,#PB_Text_Center)
      StringGadget(#dar, 223, 25, 60, 20, "",#PB_String_ReadOnly)
      
      
      ButtonGadget(#autocrop, 318, 25, 120, comboheight, "Do AutoCrop ")
      
      TextGadget(#PB_Any, 242,50, 67, 20, "Frame Rate")
      ComboBoxGadget(#framerate, 318, 50 ,120, 20,#PB_ComboBox_Editable)
      AddGadgetItem(#framerate,-1,"automatic")
      AddGadgetItem(#framerate,-1,"23.976")
      AddGadgetItem(#framerate,-1,"25.000")
      AddGadgetItem(#framerate,-1,"29.97")
      SetGadgetState(#framerate,0)
      
      
      TextGadget(#PB_Any, 242,75, 85, 20, "Aspect Ratio")
      ComboBoxGadget(#arcombo, 318, 75, 120, 20,#PB_ComboBox_Editable)
      AddGadgetItem(#arcombo,-1,"1")
      AddGadgetItem(#arcombo,-1,"1.3334")
      AddGadgetItem(#arcombo,-1,"1.7778")
      AddGadgetItem(#arcombo,-1,"1.85")
      AddGadgetItem(#arcombo,-1,"2.35")
      
      CheckBoxGadget(#anamorphic, 318, 100,115,20,"Anamorphic Resiz.")
      CheckBoxGadget(#itu, 318, 120,120,20,"Follow ITU Resizing")
      SetGadgetState(#itu,0)
      CheckBoxGadget(#deinterlace, 318, 140, 100, 20, "Deinterlace")
      
      
      TextGadget(#PB_Any, 18, 53, 75, 20, "Top Crop ---->")
      StringGadget(#topcrop, 95, 53, 60, 20, "")
      StringGadget(#leftcrop, 18, 78, 60, 20, "")
      TextGadget(#PB_Any, 90, 82, 73, 20, "<-Left | Right->")
      StringGadget(#rightcrop, 173, 78, 60, 20, "")
      TextGadget(#PB_Any, 18, 103, 90, 20, "Bottom Crop ->")
      StringGadget(#bottomcrop, 95, 103, 60, 20, "")
      TextGadget(#PB_Any, 163, 108, 60, 20, " AR Error:" ,#PB_Text_Center)
      StringGadget(#arerror, 223, 103, 60, 20, "",#PB_String_ReadOnly)
      
      TrackBarGadget(#trackwidth, 13,130,275, 17, 0, 360)
      
      TextGadget(#PB_Any,18,153,145,20,"Manually Set Width x Height:")
      StringGadget(#width, 160, 150,50, 20, "")
      TextGadget(#PB_Any, 223, 153, 10, 20, "x")
      StringGadget(#height, 238, 150, 50, 20, "")
      
      TextGadget(#PB_Any,18,183,153,20,"Set MOD Block Width x Height:")
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
      
      
      AddGadgetItem(#Panel_0, -1, "Audio")
      Frame3DGadget(#PB_Any, 8, 10, 220, 165, "Audio Parameters")
      Frame3DGadget(#PB_Any, 238,10, 210,80, "Audio Options")
      Frame3DGadget(#PB_Any, 238,95, 210,80, "Other Options")
      
      TextGadget(#PB_Any, 18, 73, 70, 20, "Audio Bitrate:")
      ComboBoxGadget(#audibit, 98, 68, 70, comboheight,#PB_ComboBox_Editable)
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
      TextGadget(#PB_Any, 178, 73, 40, 20, "kbit/s")
      TextGadget(#PB_Any, 18, 98, 70, 20, "Sampling:")
      ComboBoxGadget(#sampling, 98, 98, 70, comboheight,#PB_ComboBox_Editable)
      AddGadgetItem(#sampling,-1,"AUTO")
      AddGadgetItem(#sampling,-1,"48000")
      AddGadgetItem(#sampling,-1,"44100")
      AddGadgetItem(#sampling,-1,"22050")
      SetGadgetState(#sampling,0)
      TextGadget(#PB_Any, 178, 98, 40, 20, "hz")
      TextGadget(#PB_Any, 18, 131, 70, 20, "Channels")
      ComboBoxGadget(#channel, 98, 128, 70, comboheight)
      AddGadgetItem(#channel,-1,"Original")
      AddGadgetItem(#channel,-1,"2")
      AddGadgetItem(#channel,-1,"1")
      SetGadgetState(#channel,1)
      
      CheckBoxGadget(#audionormalize, 248, 33, 150, 20, "Normalize Audio Track")
      SetGadgetState(#audionormalize,1)
      TextGadget(#PB_Any, 248, 61, 60, 20, "Audio Gain:")
      SpinGadget(#audiogain, 328, 58, 100, 20, 0, 50,#PB_Spin_Numeric)
      
      TextGadget(#PB_Any, 248, 118, 90, 20, "Encode only first")
      StringGadget(#vframes, 340, 115, 50, 20,"",#PB_String3D_Numeric)
      TextGadget(#PB_Any,395,118,50,20,"frames")
      
      
      TextGadget(#PB_Any, 15, 188, 70, 20, "Audio track:")
      ComboBoxGadget(#audiotrack, 85, 180, 363, comboheight)
      
      TextGadget(#PB_Any, 18, 38, 80, 20, "Audio Codec:")      
      ComboBoxGadget(#audiocodec, 98, 38,110,comboheight )
      AddGadgetItem(#audiocodec,-1,"MP3 Audio")
      AddGadgetItem(#audiocodec,-1,"AAC Audio")
      AddGadgetItem(#audiocodec,-1,"FLAC Audio")
      AddGadgetItem(#audiocodec,-1,"OGG Audio")
      AddGadgetItem(#audiocodec,-1,"Copy Audio")
      AddGadgetItem(#audiocodec,-1,"WMA Audio")
      AddGadgetItem(#audiocodec,-1,"No Audio")
      SetGadgetText(#audiocodec,"MP3 Audio")
      SetGadgetState(#audiocodec,0)
      
      ;- queue
      AddGadgetItem(#Panel_0, -1, "Queue")
      Frame3DGadget(#PB_Any, 8,5, 440, 200, "Queue")
      EditorGadget(#queue,18,28,415,140)
      ButtonGadget(#addtoqueue,18,180,90,comboheight,"Add to Queue")
      ButtonGadget(#removequeuejob,125,180,110,comboheight,"Remove last job")
      ButtonGadget(#startqueue,250,180,80,comboheight,"Start Queue")
      
      ButtonGadget(#buttonaddtoqueue,340,180,40,comboheight,"add ...")
      ComboBoxGadget(#addedtoqueue,380,180,65,20,#PB_ComboBox_Editable)
      AddGadgetItem(#addedtoqueue,-1,"pause")
      AddGadgetItem(#addedtoqueue,-1,"shutdown")
      AddGadgetItem(#addedtoqueue,-1,"Edit Me...")
      SetGadgetState(#addedtoqueue,0)
      
      
      ;- Tools
      AddGadgetItem(#Panel_0, -1, "Tools (not working)")
      ComboBoxGadget(#muxtype, 78, 158, 100, 20)
      
      ;- Panel10
      PanelGadget(#Panel_2, 8, 8, 440, 200)
        AddGadgetItem(#Panel_2, -1, "Mux")
        ButtonGadget(#muxvideotrackbtt, 8, 18, 90, 20, "Video Track ...")
        StringGadget(#muxvideotrack, 108, 18, 320, 20, "")
        ButtonGadget(#muxaudiotrackbtt, 8, 48, 90, 20, "Audio Track ...")
        StringGadget(#muxaudiotrack1, 108, 48, 320, 20, "")
        ButtonGadget(#muxaudiotrack2btt, 8, 78, 90, 20, "Audio Track 2 ...")
        StringGadget(#muxaudiotrack2, 108, 78, 320, 20, "")
        TextGadget(#PB_Any, 8, 133, 60, 20, "Mux type:")
        ButtonGadget(#startmux, 308, 108, 120, 20, "Start Mux")
        AddGadgetItem(#Panel_2, -1, "Demux")
        ButtonGadget(#demuxinputbutton, 8, 18, 90, 20, "Input file ...")
        StringGadget(#demuxinputfile, 108, 18, 310, 20, "")
        ButtonGadget(#demuxpathbutton, 8, 48, 90, 20, "Demux path ...")
        StringGadget(#demuxpathtext, 108, 48, 310, 20, "")
        TextGadget(#PB_Any, 8, 93, 90, 20, "What demux ...")
        ComboBoxGadget(#whatdemux, 108, 88, 160, 20)
        ButtonGadget(#startdemux, 308, 88, 120, 20, "Start Demuxing")
        AddGadgetItem(#Panel_2, -1, "Fix")
        ButtonGadget(#fixbutton, 8, 18, 90, 20, "Fix it ...")
        StringGadget(#filetofix, 108, 18, 320, 20, "")
        ButtonGadget(#outputbuttonfix, 8, 48, 90, 20, "Output Fixed ...")
        StringGadget(#filefixed, 108, 48, 320, 20, "")
        ButtonGadget(#startfix, 308, 78, 120, 20, "Start Fix")
      CloseGadgetList()
      ;CloseGadgetList()
      
      GadgetToolTip(#play,"Press this button for playing input file")
      GadgetToolTip(#encode,"Click here for start encoding!")
      GadgetToolTip(#preview,"Click here for a preview resized")
      GadgetToolTip(#open,"Click here for selecting input file")
      GadgetToolTip(#outputstring,"Select output file")
      GadgetToolTip(#save,"Click here for selecting output file name")
      GadgetToolTip(#presetsummary,"Select a preset for encoding")
      GadgetToolTip(#pass,"Select number of pass/type of encoding")
      GadgetToolTip(#videokbits,"This is the bitrate video. You can manually edit it")
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
      GadgetToolTip(#autocrop,"Click here for automatic crop of movie. You need mplayer")
      GadgetToolTip(#framerate,"This is the framerate applyed")
      GadgetToolTip(#arcombo,"Aspect Ratio of movie")
      GadgetToolTip(#deinterlace,"Apply a deinterlace filter")
      GadgetToolTip(#audiocodec,"This is the codec audio to apply")
      GadgetToolTip(#audibit,"Bitrate of audio")
      GadgetToolTip(#sampling,"Sampling of audio. Do attention")
      GadgetToolTip(#channel,"Number of channels to output")
      GadgetToolTip(#audiotrack,"Select the audio track")
      GadgetToolTip(#audionormalize,"Normalize the volume")
      GadgetToolTip(#audiogain,"Apply a fixed volume gain")
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
; IDE Options = PureBasic 4.60 Beta 4 (Windows - x86)
; CursorPosition = 179
; FirstLine = 176
; Folding = -
; DisableDebugger
; CompileSourceDirectory
; EnableCompileCount = 62
; EnableBuildCount = 10
; EnableExeConstant