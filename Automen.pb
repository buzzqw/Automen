; PureBasic Visual Designer v3.95 build 1485 (PB4Code)

IncludeFile "automen_include.pb"

Global inputfile.s,framecount.l,framerate.f,ar.s,twidth.l,mess.s,theight.l,tsec.l,height.l,width.l,videocodec.s
Global acbottom.l,acleft.l,acright.l,actop.l,aspectinfo.f,mencoderbat.s,bitrate.s
Global messinfo.s,outputinfo.s,here.s,outputfile.s,pgcid.l,mencoder.s,workpath.s
Global here.s,queue.l, queuecount.l,passx.l,mplayer.s,mkvmerge.s,mp4box.s,pgc.s,start.l,mux.s,vcrop.s,handbrakecli.s,ffmpeg.s,extsubs.s
Global linux,windows

Declare start()

Procedure handbrakeoff()
  
  StatusBarText(#statusbar, 0, "Resetting video and audio codec!")
  
  If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding" Or GetGadgetText(#encodewith)="Mencoder for Encoding" Or GetGadgetText(#encodewith)="Use AviSynth (only for X264)" Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder" Or GetGadgetText(#encodewith)="Use ffmpeg as encoder"
    
    ClearGadgetItems(#audiocodec)
    AddGadgetItem(#audiocodec,-1,"MP3 Audio")
    AddGadgetItem(#audiocodec,-1,"AAC Audio")
    AddGadgetItem(#audiocodec,-1,"OGG Audio")
    AddGadgetItem(#audiocodec,-1,"Copy Audio")
    AddGadgetItem(#audiocodec,-1,"No Audio")
    
    If GetGadgetText(#encodewith)="Mencoder for Encoding" Or GetGadgetText(#encodewith)="Use AviSynth (only for X264)" Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder" Or GetGadgetText(#encodewith)="Use ffmpeg as encoder"
      AddGadgetItem(#audiocodec,-1,"AC3 Audio")
    EndIf
    
    If GetGadgetText(#encodewith)="Use ffmpeg as encoder"
      AddGadgetItem(#audiocodec,-1,"FLAC Audio")
      AddGadgetItem(#audiocodec,-1,"WMA Audio")
    EndIf
    
    SetGadgetText(#audiocodec,"MP3 Audio")
    
    ClearGadgetItems(#audibit)
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
    
  EndIf
  
  If GetGadgetText(#encodewith)="Use AviSynth (only for X264)"  Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder"
    StatusBarText(#statusbar, 0, "Resetting video And audio codec! Forcing video codec to X264")
  EndIf
  
  
  ClearGadgetItems(#pass)
  AddGadgetItem(#pass,-1,"1 pass")
  AddGadgetItem(#pass,-1,"2 pass")
  AddGadgetItem(#pass,-1,"CRF 1 pass")
  
  If GetGadgetText(#encodewith)="Use ffmpeg as encoder"
    AddGadgetItem(#pass,-1,"Copy Video")
    AddGadgetItem(#pass,-1,"Same Quality")
  EndIf
  
  If GetGadgetText(#encodewith)="Use AviSynth (only for X264)"  Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder"
    AddGadgetItem(#pass,-1,"1 pass + CRF Mode")
  EndIf
  
  If GetGadgetText(#encodewith)="Use X264 as demuxer and encoder"
    GadgetToolTip(#width,"You cannot change resolution while using X264 as demuxer and encoder")
  Else
    GadgetToolTip(#width,"This is the WIDTH detected by Mplayer. Feel free To change it If wrong")
  EndIf
  
  
  SetGadgetState(#pass,0)
  
  If GetGadgetText(#encodewith)="Mencoder for Encoding" Or GetGadgetText(#encodewith)="Use AviSynth (only for X264)"  Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder" Or GetGadgetText(#encodewith)="Use ffmpeg as encoder"
    ClearGadgetItems(#channel)
    AddGadgetItem(#channel,-1,"Original")
    AddGadgetItem(#channel,-1,"2")
    AddGadgetItem(#channel,-1,"1")
  EndIf
  
  If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding"
    ClearGadgetItems(#channel)
    AddGadgetItem(#channel,-1,"mono")
    AddGadgetItem(#channel,-1,"stereo")
    AddGadgetItem(#channel,-1,"dpl1")
    AddGadgetItem(#channel,-1,"dpl2")
    AddGadgetItem(#channel,-1,"6ch")
  EndIf
  SetGadgetState(#channel,1)
  
  If GetGadgetText(#encodewith)="Mencoder for Encoding" Or GetGadgetText(#encodewith)="Use AviSynth (only for X264)" Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder" Or GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding" Or GetGadgetText(#encodewith)="Use ffmpeg as encoder"
    ClearGadgetItems(#sampling)
    AddGadgetItem(#sampling,-1,"AUTO")
    AddGadgetItem(#sampling,-1,"48000")
    AddGadgetItem(#sampling,-1,"44100")
    AddGadgetItem(#sampling,-1,"32000")
    AddGadgetItem(#sampling,-1,"24000")
    AddGadgetItem(#sampling,-1,"22050")
  EndIf
  
  
  If GetGadgetText(#encodewith)="Mencoder for Encoding" Or GetGadgetText(#encodewith)="Use ffmpeg as encoder"
    ClearGadgetItems(#videocodec)
    AddGadgetItem(#videocodec,-1,"XviD")
    AddGadgetItem(#videocodec,-1,"Mpeg4")
    AddGadgetItem(#videocodec,-1,"X264")
    
    If GetGadgetText(#encodewith)="Use ffmpeg as encoder"
      AddGadgetItem(#videocodec,-1,"WMV")
    EndIf
    
    
    ClearGadgetItems(#container)
    AddGadgetItem(#container,-1,"AVI")
    AddGadgetItem(#container,-1,"MP4")
    AddGadgetItem(#container,-1,"MKV")
    
    If GetGadgetText(#encodewith)="Use ffmpeg as encoder"
      AddGadgetItem(#container,-1,"WMV")
    EndIf
    
    DisableGadget(#mp3mode,0)
    DisableGadget(#resizer,0)
    DisableGadget(#noodml,0)
    DisableGadget(#ffourcc,0)
    DisableGadget(#subs,0)
    DisableGadget(#audionormalize,0)
    DisableGadget(#multithread,0)
    
    SetGadgetText(#text50,"Audio Bitrate:")
    SetGadgetText(#text51,"kbit/s")
    
    GadgetToolTip(#audibit,"Bitrate of audio")
    
  EndIf
  
  If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding"
    ClearGadgetItems(#videocodec)
    AddGadgetItem(#videocodec,-1,"Mpeg4")
    AddGadgetItem(#videocodec,-1,"X264")
    
    ClearGadgetItems(#container)
    AddGadgetItem(#container,-1,"MP4")
    AddGadgetItem(#container,-1,"MKV")
    
    DisableGadget(#mp3mode,1)
    DisableGadget(#resizer,1)
    DisableGadget(#noodml,1)
    DisableGadget(#ffourcc,1)
    DisableGadget(#audionormalize,0)
    DisableGadget(#multithread,1)
    
    GadgetToolTip(#audibit,"Bitrate of audio")
    
    SetGadgetText(#text50,"Audio Bitrate:")
    SetGadgetText(#text51,"kbit/s")
    
  EndIf
  
  If GetGadgetText(#encodewith)="Use AviSynth (only for X264)"  Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder"
    ClearGadgetItems(#videocodec)
    StatusBarText(#statusbar, 0, "Resetting video And audio codec! Forcing video codec to X264")
    AddGadgetItem(#videocodec,-1,"X264")
    
    ClearGadgetItems(#container)
    AddGadgetItem(#container,-1,"MP4")
    AddGadgetItem(#container,-1,"MKV")
    AddGadgetItem(#container,-1,"H264")
    AddGadgetItem(#container,-1,"FLV")
    
    DisableGadget(#mp3mode,0)
    DisableGadget(#resizer,0)
    DisableGadget(#noodml,1)
    DisableGadget(#ffourcc,1)
    DisableGadget(#audionormalize,0)
    DisableGadget(#multithread,1)
    
    SetGadgetText(#text50,"Audio Bitrate:")
    SetGadgetText(#text51,"kbit/s")
    
    GadgetToolTip(#audibit,"Bitrate of audio")
    
  EndIf
  
  SetGadgetState(#sampling,0)
  SetGadgetState(#videocodec,0)
  SetGadgetState(#container,0)
  DisableGadget(#allowresize,0)
  
EndProcedure

Procedure makereport()
  
  If GetGadgetText(#queue)=""
    queue.l=1
    
    If GetGadgetText(#width)=""
      MessageRequester("AutoMen", "Attention!"+Chr(13)+Chr(10)+"Load file First!")
      ProcedureReturn
    EndIf
    
    If GetGadgetText(#encodewith)<>"Use HandBrakeCLI for Encoding"
      queuecount.l=queuecount.l+1
      queue.l=1
      If GetGadgetText(#pass)="1 pass" : passx.l=2 : start() : EndIf
      If GetGadgetText(#pass)="2 pass"
        passx.l=3 : start()
        passx.l=4 : start()
      EndIf
      If GetGadgetText(#pass)="CRF 1 pass"
        passx.l=5
        start()
      EndIf
      If GetGadgetText(#pass)="Copy Video"
        passx.l=7
        start()
      EndIf
    EndIf
    If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding"
      queuecount.l=queuecount.l+1
      queue.l=1
      start()
    EndIf
    
  EndIf
  
  
  CreateFile(147,here.s+"Post_This_File.txt")
  
  WriteStringN(147,"[CODE]AutoMen "+ver.s+" report")
  WriteStringN(147,"")
  WriteStringN(147,"Input File: "+inputfile.s+" ( "+GetGadgetText(#inputstring)+" )")
  WriteStringN(147,"")
  WriteStringN(147,GetGadgetText(#basicfile))
  WriteStringN(147,"")
  WriteStringN(147,"Resized resolution: "+GetGadgetText(#width)+" / "+GetGadgetText(#height))
  WriteStringN(147,"Crop Values : "+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)+":"+GetGadgetText(#rightcrop)+":"+GetGadgetText(#bottomcrop))
  If GetGadgetState(#itu)=1 : WriteStringN(147,"Activate: Follow ITU Resizing") : EndIf
  If GetGadgetState(#anamorphic)=1 : WriteStringN(147,"Activate: Anamorphic Resize") : EndIf
  If GetGadgetState(#allowresize)=0 : WriteStringN(147,"No Resize & Crop: On") : EndIf
  WriteStringN(147,"")
  WriteStringN(147,"Encoding With: "+GetGadgetText(#videocodec))
  WriteStringN(147,"Container: "+GetGadgetText(#container))
  WriteStringN(147,"Encoding Mode: "+GetGadgetText(#pass))
  WriteStringN(147,"Video Bitrate: "+GetGadgetText(#videokbits))
  WriteStringN(147,"Denoise Level: "+GetGadgetText(#denoise))
  WriteStringN(147,"Resizer : "+GetGadgetText(#resizer))
  WriteStringN(147,"")
  
  If GetGadgetState(#noodml)=1 : WriteStringN(147,"Don't use ODML: On") : EndIf
  If GetGadgetState(#ffourcc)=1 : WriteStringN(147,"Use DIVX as FourCC for XviD: On") : EndIf
  WriteStringN(147,GetGadgetText(#encodewith))
  WriteStringN(147,"")
  WriteStringN(147,"Audio Track: "+GetGadgetText(#audiotrack))
  WriteStringN(147,"Audio Codec: "+GetGadgetText(#audiocodec))
  WriteStringN(147,"Audio Bitrate: "+GetGadgetText(#audibit))
  WriteStringN(147,"Audio Channels: "+GetGadgetText(#channel))
  WriteStringN(147,"Audio Mode: "+GetGadgetText(#mp3mode))
  If GetGadgetState(#audionormalize)=1 : WriteStringN(147,"Audio Normalize: On") : EndIf
  WriteStringN(147,"")
  WriteStringN(147,"Start Queue ->")
  WriteStringN(147,GetGadgetText(#queue))
  WriteStringN(147,"-> End Queue")
  WriteStringN(147,"")
  
  
  WriteString(147,"[/CODE]")
  
  CloseFile(147)
  
  MessageRequester("AutoMen","               ---> Post_This_File.txt <--- file created in "+Chr(13)+Chr(10)+Chr(10)+here.s+" folder")
  RunProgram("Post_This_File.txt",here.s,"")
  
EndProcedure


Procedure sanitycheck()
  
  
  If Val(GetGadgetText(#videokbits))>100 And FindString(GetGadgetText(#pass),"CRF",0)=0
    SetGadgetColor(#videokbits,#PB_Gadget_BackColor,$33CC00)
  Else
    SetGadgetColor(#videokbits,#PB_Gadget_BackColor,$0000FF)
  EndIf
  
  If Val(GetGadgetText(#videokbits))>10000 : SetGadgetColor(#videokbits,#PB_Gadget_BackColor,$0000FF) : EndIf
  
  If Val(GetGadgetText(#framecountf))>100
    SetGadgetColor(#framecountf,#PB_Gadget_BackColor,$33CC00)
  Else
    SetGadgetColor(#framecountf,#PB_Gadget_BackColor,$0000FF)
  EndIf
  
  If Val(GetGadgetText(#frameratef))>20
    SetGadgetColor(#frameratef,#PB_Gadget_BackColor,$33CC00)
  Else
    SetGadgetColor(#frameratef,#PB_Gadget_BackColor,$0000FF)
  EndIf
  
  SetGadgetText(#videolenght,StrF(framecount.l/framerate.f/60,2))
  
  
EndProcedure

Procedure savesetting()
  
  CreatePreferences(here.s+"automen.ini")
  
  PreferenceComment("AutoMEN default parameters")
  PreferenceGroup("AutoMEN")
  WritePreferenceString("AutoMEN version ",ver.s)
  WritePreferenceString("Path to Mencoder",GetGadgetText(#pathtomencoder))
  WritePreferenceString("Path to Mplayer",GetGadgetText(#pathtomplayer))
  WritePreferenceString("Path to Mp4box",GetGadgetText(#pathtomp4box))
  WritePreferenceString("Path to Mkvmerge",GetGadgetText(#pathtomkvmerge))
  WritePreferenceString("Path to HandBrakeCLI",GetGadgetText(#pathtohandbrakecli))
  WritePreferenceString("Path to FFmpeg",GetGadgetText(#pathtoffmpeg))
  WritePreferenceString("Select Encoder",GetGadgetText(#encodewith))
  WritePreferenceString("Select Denoise Level",GetGadgetText(#denoise))
  WritePreferenceString("Select Resizer",GetGadgetText(#resizer))
  WritePreferenceString("Select Audio Codec",GetGadgetText(#audiocodec))
  WritePreferenceString("Select Video Codec",GetGadgetText(#videocodec))
  WritePreferenceString("Select Container",GetGadgetText(#container))
  WritePreferenceString("Select Pass",GetGadgetText(#pass))
  WritePreferenceString("Select Encoding Quality",Str(GetGadgetState(#speedquality)))
  
  ClosePreferences()
  
  If FileSize(here.s+"automen.ini")<>-1  :  MessageRequester("AutoMen","Settings Saved") : EndIf
  
EndProcedure

Procedure loaddefault()
  
  If OpenPreferences(here.s+"automen.ini")
    PreferenceGroup("AutoMEN")
    SetGadgetText(#pathtomencoder,ReadPreferenceString("Path to Mencoder", GetCurrentDirectory()))
    SetGadgetText(#pathtomplayer,ReadPreferenceString("Path to Mplayer", GetCurrentDirectory()))
    SetGadgetText(#pathtomp4box,ReadPreferenceString("Path to Mp4box", GetCurrentDirectory()))
    SetGadgetText(#pathtomkvmerge,ReadPreferenceString("Path to Mkvmerge", GetCurrentDirectory()))
    SetGadgetText(#pathtoffmpeg,ReadPreferenceString("Path to FFmpeg", GetCurrentDirectory()))
    SetGadgetText(#pathtohandbrakecli,ReadPreferenceString("Path to HandBrakeCLI", GetCurrentDirectory()))
    
    clean.s=ReadPreferenceString("Delete temporary files", "no")
    pathdestination.s=ReadPreferenceString("Destination Folder", "")
    
    ClosePreferences()
    
  EndIf
  
  
EndProcedure


Procedure mencoder()
  
  mux.s=""
  
  outputfile.s=Mid(GetGadgetText(#outputstring),0,Len(GetGadgetText(#outputstring))-4)+".avi"
  
  If GetGadgetText(#width)=""
    MessageRequester("AutoMen", "Attention!"+Chr(10)+"Analyze file First!")
    ProcedureReturn
  EndIf
  
  If FindString(inputfile.s,"_1",0)
    For aa=1 To 128
      If FileSize(GetPathPart(inputfile)+Mid(GetFilePart(inputfile),0,Len(GetFilePart(inputfile))-3-Len(GetExtensionPart(inputfile)))+"_"+Str(aa)+"."+GetExtensionPart(inputfile))<>-1
        inputfile1.s=inputfile1.s+" "+Chr(34)+GetPathPart(inputfile)+Mid(GetFilePart(inputfile),0,Len(GetFilePart(inputfile))-3-Len(GetExtensionPart(inputfile)))+"_"+Str(aa)+"."+GetExtensionPart(inputfile)+Chr(34)
      EndIf
    Next aa
    If FileSize(GetPathPart(inputfile)+Mid(GetFilePart(inputfile),0,Len(GetFilePart(inputfile))-3-Len(GetExtensionPart(inputfile)))+"_2."+GetExtensionPart(inputfile))<>-1
      inputfile.s=Mid(inputfile1.s,3,Len(inputfile1.s)-3)
    EndIf
  EndIf
    
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="ifo"
    dump.s=mplayer.s+" dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(GetGadgetText(#inputstring)),0,Len(GetPathPart(GetGadgetText(#inputstring)))-1)+Chr(34)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34)
     AddGadgetItem(#queue,0,dump.s)
    inputfile.s=workpath.s+"film.vob"
  EndIf
   
  mencoderbat.s=""
    
  If linux=#True : mencoderbat.s=mencoder.s+" " : EndIf
  If windows=#True : mencoderbat.s=Chr(34)+mencoder.s+Chr(34)+" " : EndIf
  
  If GetGadgetText(#bottomcrop)<>"" Or GetGadgetText(#topcrop)<>"" Or GetGadgetText(#leftcrop)<>"" Or GetGadgetText(#rightcrop)<>""
    vcrop.s="crop="+Str(twidth.l-Val(GetGadgetText(#leftcrop))-Val(GetGadgetText(#rightcrop)))+":"+Str(theight.l-Val(GetGadgetText(#topcrop))-Val(GetGadgetText(#bottomcrop)))+":"+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)+","
  EndIf
  
  If GetGadgetText(#mdeint)="FILM NTSC (29.97->23.976)" : mdeint.s=" -vf pullup,softskip," : framer.s="23.976 " : EndIf
  If GetGadgetText(#mdeint)="Interlaced" : mdeint.s=" -vf yadif," :  EndIf
  If GetGadgetText(#mdeint)="Telecine" : mdeint.s=" -vf filmdint," :  framer.s="23.976 " : EndIf
  If GetGadgetText(#mdeint)="Mixed Prog/Telecine" : mdeint.s=" -vf filmdint," :  framer.s="23.976 " : EndIf
  If GetGadgetText(#mdeint)="Mixed Prog/Interlaced" : mdeint.s=" -vf yadif," :  EndIf
  If GetGadgetText(#mdeint)="Change FPS to 25" : mdeint.s=" -ofps 25000/1000 -vf " :  framer.s="25 " : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 23.976" : mdeint.s=" -ofps 24000/1001 -vf " :  framer.s="23.976 " : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 29.97" : mdeint.s=" -ofps 30000/1001 -vf " :  framer.s="29.97 " : EndIf
  If GetGadgetText(#mdeint)="Progressive"  : mdeint.s="-vf " :  EndIf
  
  If GetGadgetText(#mdeint)="Progressive"
    If videocodec.s="mpeg2" : mdeint.s=" -mc 0 -vc mpeg12 -vf " : EndIf
  EndIf
  
  If GetGadgetText(#mdeint)="Interlaced"
    If videocodec.s="mpeg2" : mdeint.s=" -mc 0 -vc mpeg12 -field-dominance -1 "+mdeint.s : EndIf
  EndIf
  
  denoise.s=""
  
  If GetGadgetText(#denoise)="NONE" : denoise.s="" : EndIf
  If GetGadgetText(#denoise)="Super Light" : denoise.s="hqdn3d=1" : EndIf
  If GetGadgetText(#denoise)="Light" : denoise.s="hqdn3d=2" : EndIf
  If GetGadgetText(#denoise)="Normal" : denoise.s="hqdn3d=4" : EndIf
  If GetGadgetText(#denoise)="Severe" : denoise.s="hqdn3d=6" : EndIf
  
  If GetGadgetState(#allowresize)=1
    mencoderbat.s=mencoderbat.s+mdeint.s+" "+vcrop.s+",scale="+GetGadgetText(#width)+":"+GetGadgetText(#height)
    If denoise.s<>"" :  mencoderbat.s=mencoderbat.s+","+denoise.s+" " : EndIf
  EndIf
  
  If GetGadgetState(#allowresize)=0
    If mdeint.s="-vf " Or mdeint.s=" -mc 0 -vc mpeg12 -vf "
      If denoise.s=""
        mdeint.s=""
      EndIf
    EndIf
    
    mencoderbat.s=mencoderbat.s+mdeint.s
    If denoise.s<>"" :  mencoderbat.s=mencoderbat.s+" "+denoise.s+" " : EndIf
  EndIf
  
  
  If GetGadgetText(#mdeint)="FILM NTSC (29.97->23.976)"  Or GetGadgetText(#mdeint)="Telecine" Or GetGadgetText(#mdeint)="Mixed Prog/Telecine"
    mencoderbat.s=mencoderbat.s+" -ofps 24000/1001 "
  EndIf
  
  If GetGadgetText(#resizer)<>"2 bicubic" : mencoderbat.s=mencoderbat.s+"-sws "+Str(GetGadgetState(#resizer))+" " : EndIf
  
  If GetGadgetState(#noodml)=1 : mencoderbat.s=mencoderbat.s+" -noodml " : EndIf
  
  sub.s=""
  
  If GetGadgetText(#subs)<>"none" And GetGadgetText(#subs)<>"" And LCase(GetExtensionPart(GetGadgetText(#inputstring)))<>"ifo"
    sub.s=" -sid "+StringField(StringField(StringField(GetGadgetText(#subs),2,"-sid"),1,","),2," ")+" "
    sub.s=sub.s+" -subfont-autoscale 3 -subfont-text-scale 5 "
  EndIf
  
  If GetGadgetText(#subs)<>"none" And GetGadgetText(#subs)<>"" And LCase(GetExtensionPart(GetGadgetText(#inputstring)))="ifo"
    sub.s=" -sid "+Trim(StringField(StringField(GetGadgetText(#subs),2,":"),1,"language"))+" "
    sub.s=sub.s+" -subfont-autoscale 3 -subfont-text-scale 5 "
  EndIf
  
  If FindString(GetGadgetText(#subs),"/",0) Or FindString(GetGadgetText(#subs),"\",0)
    sub.s=" -sub "+Chr(34)+GetGadgetText(#subs)+Chr(34)+" "
  EndIf
  
  If sub.s<>"" : mencoderbat.s=mencoderbat.s+sub.s : EndIf
  
  If GetGadgetState(#ffourcc)=1 : fourcc.s=" -ffourcc DIVX "  : EndIf
  
  mencoderbat.s=mencoderbat.s+" -o "+Chr(34)+outputfile.s+Chr(34)+" "
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If ReadFile(777,here.s+"menprofile.txt")
    While Eof(777) = #False
      line.s = LCase(ReadString(777))
      If FindString(line.s,LCase(GetGadgetText(#videocodec))+";",0) And FindString(line.s,"mencoder",0) And FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0)
        encostring.s=StringField(line.s,4,";")
      EndIf
    Wend
    CloseFile(777)
  EndIf
  
  If passx.l=3 : encostring.s=encostring.s+":turbo" :EndIf
  If passx.l=2 : encostring.s=ReplaceString(encostring.s,"bitrate","bitrate="+bitrate.s) : EndIf
  If passx.l=3 : encostring.s=ReplaceString(encostring.s,"bitrate","bitrate="+bitrate.s+":pass=1") : EndIf
  If passx.l=4 : encostring.s=ReplaceString(encostring.s,"bitrate","bitrate="+bitrate.s+":pass=2") : EndIf
  If passx.l=5
    If GetGadgetText(#videocodec)="XviD" : encostring.s=ReplaceString(encostring.s,"bitrate","fixed_quant="+bitrate.s) : EndIf
    If GetGadgetText(#videocodec)="Mpeg4" : encostring.s=ReplaceString(encostring.s,"vbitrate","vqscale="+bitrate.s) : EndIf
    If GetGadgetText(#videocodec)="X264" : encostring.s=ReplaceString(encostring.s,"bitrate","crf="+bitrate.s) : EndIf
  EndIf
  If passx.l=7 : encostring.s=ReplaceString(encostring.s,encostring.s,"-ovc copy ") : EndIf
  
  If GetGadgetText(#videocodec)="Mpeg4" : encostring.s=ReplaceString(encostring.s,"pass=","vpass=") : EndIf
  
  mencoderbat.s=mencoderbat.s+encostring.s+" "
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    
    If FindString(GetGadgetText(#audiotrack),"none",0)=0
      
      If FindString(GetGadgetText(#audiotrack),"audio stream:",0) And FindString(GetGadgetText(#audiotrack),"language:",0)
        mencoderbat.s=mencoderbat.s+"-aid "+StringField(GetGadgetText(#audiotrack),CountString(GetGadgetText(#audiotrack),":")+1,":")+" "
      EndIf
      
      If FindString(GetGadgetText(#audiotrack),"ID_AUDIO_ID",0)
        mencoderbat.s=mencoderbat.s+"-aid "+StringField(GetGadgetText(#audiotrack),2,"=")+" "
      EndIf
      
      ;If LCase(GetExtensionPart(inputfile.s))="mkv"
      ;  mencoderbat.s=mencoderbat.s+"-aid "+StringField(StringField(StringField(GetGadgetText(#audiotrack),2,"-"),2," "),1,",")+" "
      ;EndIf
      
      If FindString(GetGadgetText(#audiotrack),"-aid",0)
        For aa=1 To CountString(GetGadgetText(#audiotrack),",")+1
          mess.s=StringField(GetGadgetText(#audiotrack),aa,",")
          If FindString(mess.s,"-aid",0) : mencoderbat.s=mencoderbat.s+" "+ReplaceString(mess.s,",","")+" "
        EndIf
      Next aa
    EndIf
    
    
    If GetGadgetText(#audiocodec)="MP3 Audio" : mencoderbat.s=mencoderbat.s+" -oac mp3lame -lameopts "+GetGadgetText(#mp3mode)+":br="+GetGadgetText(#audibit)+" " : EndIf
    If GetGadgetText(#audiocodec)="AAC Audio" : mencoderbat.s=mencoderbat.s+" -oac faac -faacopts br="+GetGadgetText(#audibit)+":mpeg=4:tns:object=2 " : EndIf
    If GetGadgetText(#audiocodec)="OGG Audio" : mencoderbat.s=mencoderbat.s+" -oac lavc -lavcopts acodec=vorbis:abitrate="+GetGadgetText(#audibit)+" " : EndIf
    If GetGadgetText(#audiocodec)="AC3 Audio" : mencoderbat.s=mencoderbat.s+" -oac lavc -lavcopts acodec=ac3:abitrate="+GetGadgetText(#audibit)+" " : EndIf
    If GetGadgetText(#audiocodec)="Copy Audio" : mencoderbat.s=mencoderbat.s+" -oac copy " : EndIf
    If GetGadgetText(#audiocodec)="No Audio" : mencoderbat.s=mencoderbat.s+" -nosound " : EndIf
    
    If GetGadgetText(#audiocodec)<>"No Audio"
      If GetGadgetText(#audiocodec)<>"Copy Audio"
        If GetGadgetState(#audionormalize)=1 : mencoderbat.s=mencoderbat.s+" -af volnorm=1 " : EndIf
        If GetGadgetText(#channel)="1" : mencoderbat.s=mencoderbat.s+" -channels 1 " : EndIf
        If GetGadgetText(#channel)="2" : mencoderbat.s=mencoderbat.s+" -channels 2 " : EndIf
        If GetGadgetText(#channel)="Original" : mencoderbat.s=mencoderbat.s+" " : EndIf
      EndIf
    EndIf
    
  EndIf
  
  If FindString(GetGadgetText(#audiotrack),"none",0) : mencoderbat.s=mencoderbat.s+" -nosound " : EndIf
  
EndIf

If GetGadgetState(#multithread)=0
  If windows=#True : mencoderbat.s=mencoderbat.s+" -lavdopts threads="+StrF(Val(GetEnvironmentVariable("NUMBER_OF_PROCESSORS")),0)+" -lavcopts threads="+StrF(Val(GetEnvironmentVariable("NUMBER_OF_PROCESSORS")),0)+" " : EndIf
  If linux=#True : mencoderbat.s=mencoderbat.s+" -lavdopts threads=2 -lavcopts threads=2 " : EndIf
EndIf

mencoderbat.s=mencoderbat.s+" -passlogfile "+Chr(34)+here.s+"automen_statsfile.log"+Chr(34)+" "

If passx.l=3 : mencoderbat.s=mencoderbat.s+" -nosound " : EndIf

If LCase(GetExtensionPart(inputfile.s))<>"ifo"
  mencoderbat.s=mencoderbat.s+" "+Chr(34)+inputfile.s+Chr(34)
EndIf

If LCase(GetExtensionPart(inputfile.s))="ifo"
  inputfile.s="dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(inputfile.s),0,Len(GetPathPart(inputfile.s))-1)+Chr(34)
  mencoderbat.s=mencoderbat.s+" "+inputfile.s
EndIf

mencoderbat.s=ReplaceString(mencoderbat.s,", ,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,", ,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,"  "," ")
mencoderbat.s=ReplaceString(mencoderbat.s,"-vf,crop","-vf crop",#PB_String_NoCase)
mencoderbat.s=ReplaceString(mencoderbat.s,"  "," ")
mencoderbat.s=ReplaceString(mencoderbat.s,"  "," ")
mencoderbat.s=ReplaceString(mencoderbat.s,"  "," ")
mencoderbat.s=ReplaceString(mencoderbat.s,", ",",")
mencoderbat.s=ReplaceString(mencoderbat.s,",,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,",,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,",,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,",,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,",,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,",,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,",,",",")
mencoderbat.s=ReplaceString(mencoderbat.s,"-vf ,scale","-vf scale")
mencoderbat.s=ReplaceString(mencoderbat.s,Chr(34)+"dvd://","dvd://")
mencoderbat.s=ReplaceString(mencoderbat.s,Chr(34)+Chr(34),Chr(34))
mencoderbat.s=ReplaceString(mencoderbat.s,Chr(34)+Chr(34),Chr(34))
mencoderbat.s=ReplaceString(mencoderbat.s,Chr(34)+Chr(34),Chr(34))
mencoderbat.s=ReplaceString(mencoderbat.s,",-"," -")
mencoderbat.s=ReplaceString(mencoderbat.s,",-"," -")


If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
  mux.s=""
  
  If GetGadgetText(#mdeint)="FILM NTSC (29.97->23.976)" : framerate.f=23.976 : EndIf
  If GetGadgetText(#mdeint)="Telecine" : framerate.f=23.976 : EndIf
  If GetGadgetText(#mdeint)="Mixed Prog/Telecine" : framerate.f=23.976 : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 23.976" : framerate.f=23.976 : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 25" : framerate.f=25 : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 29.97" : framerate.f=29.97 : EndIf
  
  If GetGadgetText(#container)="MKV"
    add.s=""
    mux.s=Chr(34)+mkvmerge.s+Chr(34)+" -o "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)+" --default-duration 0:"+StrF(framerate.f,3)+"fps "+Chr(34)+outputfile.s+Chr(34)
  EndIf
  
  If GetGadgetText(#container)="MP4"
    add.s="-add "
    mux.s=Chr(34)+mp4box.s+Chr(34)+" "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)+" -add "+Chr(34)+outputfile.s+Chr(34)
  EndIf
  
  
EndIf

AddGadgetItem(#queue,-1,mencoderbat.s)

If mux.s<>""
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    AddGadgetItem(#queue,-1,mux.s)
  EndIf
EndIf


If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
  
  If GetGadgetState(#shutdown)=1
    If linux=#True : AddGadgetItem(#queue,-1,"shutdown now") : EndIf
    If windows=#True : AddGadgetItem(#queue,-1,"shutdown -s -t 30 -f") : EndIf
  EndIf
  
EndIf

If queue.l=0
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    CreateFile(666,here.s+"automen.bat")
    WriteStringN(666,"")
    WriteStringN(666,GetGadgetText(#queue))
    CloseFile(666)
    If linux=#True
      RunProgram("chmod","+x "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s,#PB_Program_Wait)
      RunProgram("xterm","-e "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s)
    Else
      RunProgram(here.s+"automen.bat","",here.s)
    EndIf
    ClearGadgetItems(#queue)
  EndIf
EndIf

EndProcedure



Procedure ffmpeg()
  
  mux.s=""
  
  outputfile.s=Mid(GetGadgetText(#outputstring),0,Len(GetGadgetText(#outputstring))-4)+"."+GetGadgetText(#container)
  
  If GetGadgetText(#width)=""
    MessageRequester("AutoMen", "Attention!"+Chr(10)+"Analyze file First!")
    ProcedureReturn
  EndIf
  
  mencoderbat.s=""
  
  
  If linux=#True : mencoderbat.s=Chr(34)+ffmpeg.s+Chr(34)+" " : EndIf
  If windows=#True : mencoderbat.s=Chr(34)+ffmpeg.s+Chr(34)+" " : EndIf
  
  mencoderbat.s=mencoderbat.s+" -i "+Chr(34)+inputfile.s+Chr(34)+" "
  
  If GetGadgetText(#pass)<>"Copy Video"
    
    If GetGadgetText(#bottomcrop)<>"" Or GetGadgetText(#topcrop)<>"" Or GetGadgetText(#leftcrop)<>"" Or GetGadgetText(#rightcrop)<>""
      
      leftcrop.l=Val(GetGadgetText(#leftcrop))
      rightcrop.l=Val(GetGadgetText(#rightcrop))
      topcrop.l=Val(GetGadgetText(#topcrop))
      bottomcrop.l=Val(GetGadgetText(#bottomcrop))
      
      ;mencoderbat.s=mencoderbat.s+"-croptop "+Str(topcrop.l)+" -cropbottom "+Str(bottomcrop.l)+" -cropleft "+Str(leftcrop.l)+" -cropright "+Str(rightcrop.l)+" "
      mencoderbat.s=mencoderbat.s+"-vf crop="+Str(twidth.l-Val(GetGadgetText(#leftcrop))-Val(GetGadgetText(#rightcrop)))+":"+Str(theight.l-Val(GetGadgetText(#topcrop))-Val(GetGadgetText(#bottomcrop)))+":"+GetGadgetText(#rightcrop)+":"+GetGadgetText(#bottomcrop)
      If GetGadgetState(#allowresize)=1
        mencoderbat.s=mencoderbat.s+",scale="+GetGadgetText(#width)+":"+GetGadgetText(#height)+" "
      EndIf
    EndIf
    
    If leftcrop.l+topcrop.l+rightcrop.l+bottomcrop.l=0
      If GetGadgetState(#allowresize)=1
        mencoderbat.s=mencoderbat.s+"-s "+GetGadgetText(#width)+"x"+GetGadgetText(#height)+" "
      EndIf
    EndIf
    
    If GetGadgetText(#mdeint)<>"Progressive" : mencoderbat.s=mencoderbat.s+"--deinterlace " : EndIf
    
    If GetGadgetText(#mdeint)="FILM NTSC (29.97->23.976)"
      mencoderbat.s=mencoderbat.s+"-r 23.976 "
    EndIf
    If GetGadgetText(#mdeint)="Telecine"
      mencoderbat.s=mencoderbat.s+"-r 23.976 "
    EndIf
    If GetGadgetText(#mdeint)="Mixed Prog/Telecine"
      mencoderbat.s=mencoderbat.s+"-r 23.976 "
    EndIf
    If GetGadgetText(#mdeint)="Change FPS to 23.976"
      mencoderbat.s=mencoderbat.s+"-r 23.976 "
    EndIf
    If GetGadgetText(#mdeint)="Change FPS to 25"
      mencoderbat.s=mencoderbat.s+"-r 25 "
    EndIf
    If GetGadgetText(#mdeint)="Change FPS to 29.97"
      mencoderbat.s=mencoderbat.s+"-r 29.97 "
    EndIf
    
    ; If GetGadgetState(#allowresize)=1
    ;   mencoderbat.s=mencoderbat.s+"-s "+GetGadgetText(#width)+"x"+GetGadgetText(#height)+" "
    ; EndIf
    
    bitrate.s=GetGadgetText(#videokbits)
    
    If ReadFile(777,here.s+"menprofile.txt")
      While Eof(777) = #False
        line.s = LCase(ReadString(777))
        If FindString(line.s,LCase(GetGadgetText(#videocodec))+";",0) And FindString(line.s,"ffmpeg",0) And FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0)
          encostring.s=StringField(line.s,4,";")
        EndIf
      Wend
      CloseFile(777)
    EndIf
    
  EndIf
  
  If passx.l=7 : mencoderbat.s=mencoderbat.s+"-vcodec copy " : EndIf
  
  If passx.l=11
    If GetGadgetText(#container)="AVI" : mencoderbat.s=mencoderbat.s+"-vcodec libxvid -sameq " : EndIf
    If GetGadgetText(#container)="MKV" : mencoderbat.s=mencoderbat.s+"-vcodec libx264 -sameq " : EndIf
    If GetGadgetText(#container)="MP4" : mencoderbat.s=mencoderbat.s+"-vcodec libx264 -sameq " : EndIf
    If GetGadgetText(#container)="WMV" : mencoderbat.s=mencoderbat.s+"-vcodec wmv2 -sameq " : EndIf
  EndIf
  
  If passx.l=2 : mencoderbat.s=mencoderbat.s+"-b "+bitrate.s+"k " : EndIf
  If passx.l=3 : mencoderbat.s=mencoderbat.s+"-b "+bitrate.s+"k -pass 1 " : EndIf
  If passx.l=4 : mencoderbat.s=mencoderbat.s+"-b "+bitrate.s+"k -pass 2 " : EndIf
  If passx.l=5 : mencoderbat.s=mencoderbat.s+"-qscale "+bitrate.s+" " : EndIf
  
  mencoderbat.s=mencoderbat.s+" "+encostring.s+" "
  
  If GetGadgetState(#multithread)=0
    If windows=#True : mencoderbat.s=mencoderbat.s+" -threads "+StrF(Val(GetEnvironmentVariable("NUMBER_OF_PROCESSORS")),0): EndIf
    If linux=#True : mencoderbat.s=mencoderbat.s+" -threads 2 " : EndIf
  EndIf
  
  audioffmpegbat.s=""
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7 Or passx.l=11
    
    If FindString(GetGadgetText(#audiotrack),"none",0)=0
      
      If GetGadgetText(#audiocodec)="MP3 Audio" : audioffmpegbat.s=" -acodec libmp3lame -ab "+GetGadgetText(#audibit)+"k " : EndIf
      If GetGadgetText(#audiocodec)="AAC Audio" : audioffmpegbat.s=" -acodec libfaac -ab "+GetGadgetText(#audibit)+"k " : EndIf
      If GetGadgetText(#audiocodec)="OGG Audio" : audioffmpegbat.s=" -acodec libvorbis -ab "+GetGadgetText(#audibit)+"k " : EndIf
      If GetGadgetText(#audiocodec)="FLAC Audio" : audioffmpegbat.s=" -acodec flac " : EndIf
      If GetGadgetText(#audiocodec)="Copy Audio" : audioffmpegbat.s=" -acodec copy " : EndIf
      If GetGadgetText(#audiocodec)="AC3 Audio" : audioffmpegbat.s=" -acodec ac3 -ab "+GetGadgetText(#audibit)+"k " : EndIf
      If GetGadgetText(#audiocodec)="WMA Audio" : audioffmpegbat.s=" -acodec wmav2 -ab "+GetGadgetText(#audibit)+"k " : EndIf
      
      If GetGadgetText(#sampling)<>"AUTO" : audioffmpegbat.s=audioffmpegbat.s+"-ar "+GetGadgetText(#sampling)+" " : EndIf
      Select GetGadgetText(#channel)
      Case "1"
        audioffmpegbat.s=audioffmpegbat.s+"-ac 1 "
      Case "2"
        audioffmpegbat.s=audioffmpegbat.s+"-ac 2 "
      EndSelect
      
      
      If FindString(GetGadgetText(#audiotrack),"audio stream:",0) And FindString(GetGadgetText(#audiotrack),"language:",0)
        audioffmpegbat.s=audioffmpegbat.s+"-map [0:0] -map ["+Str(GetGadgetState(#audiotrack))+":0] "
      EndIf
      
      If FindString(GetGadgetText(#audiotrack),"ID_AUDIO_ID",0) And GetGadgetState(#audiotrack)<>1
        ;audioffmpegbat.s=audioffmpegbat.s+"-map [0:0] -map ["+StringField(GetGadgetText(#audiotrack),2,"=")+":0] "
        audioffmpegbat.s=audioffmpegbat.s+"-map [0:0] -map ["+Str(GetGadgetState(#audiotrack))+":0] "
      EndIf
      
      If LCase(GetExtensionPart(inputfile.s))="mkv" And GetGadgetState(#audiotrack)<>1
        audioffmpegbat.s=audioffmpegbat.s+"-map [0:0] -map ["+Str(GetGadgetState(#audiotrack))+":0] "
      EndIf
      
      If GetGadgetState(#audionormalize)=1 : audioffmpegbat.s=audioffmpegbat.s+"-vol 256 " : EndIf
      
      
    EndIf
    
    If FindString(GetGadgetText(#audiotrack),"none",0) : audioffmpegbat.s=audioffmpegbat.s+" -an " : EndIf
    
  EndIf
  
  If passx.l=3 : audioffmpegbat.s=audioffmpegbat.s+" -an " : EndIf
  
  mencoderbat.s=mencoderbat.s+audioffmpegbat.s+" -y "+Chr(34)+outputfile.s+Chr(34)+" "
  
  AddGadgetItem(#queue,-1,mencoderbat.s)
  
  If mux.s<>""
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7 Or passx.l=11
      AddGadgetItem(#queue,-1,mux.s)
    EndIf
  EndIf
  
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7 Or passx.l=11
    
    If GetGadgetState(#shutdown)=1
      If linux=#True : AddGadgetItem(#queue,-1,"shutdown now") : EndIf
      If windows=#True : AddGadgetItem(#queue,-1,"shutdown -s -t 30 -f") : EndIf
    EndIf
    
  EndIf
  
  If queue.l=0
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7 Or passx.l=11
      CreateFile(666,here.s+"automen.bat")
      WriteStringN(666,"")
      WriteStringN(666,GetGadgetText(#queue))
      CloseFile(666)
      If linux=#True
        RunProgram("chmod","+x "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s,#PB_Program_Wait)
        RunProgram("xterm","-e "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s)
      Else
        RunProgram(here.s+"automen.bat","",here.s)
      EndIf
      ClearGadgetItems(#queue)
    EndIf
  EndIf
  
EndProcedure



Procedure handbrake()
  
  mencoderbat.s=""
  mux.s=""
  
  If linux=#True : mencoderbat.s=Chr(34)+handbrakecli.s+Chr(34)+" " : EndIf
  If windows=#True : mencoderbat.s=Chr(34)+handbrakecli.s+Chr(34)+" " : EndIf
  mencoderbat.s=mencoderbat.s+"-i "+Chr(34)+inputfile.s+Chr(34)+" "
  If LCase(GetExtensionPart(inputfile.s))="ifo" : mencoderbat.s=mencoderbat.s+"-t "+Str(pgcid.l)+" " : EndIf
  
  mencoderbat.s=mencoderbat.s+"--output "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)+" "
  mencoderbat.s=mencoderbat.s+"--format "+GetGadgetText(#container)+" "
  
  If  GetGadgetText(#videocodec)="XviD" : mencoderbat.s=mencoderbat.s+"--encoder ffmpeg " : EndIf
  If GetGadgetText(#videocodec)="Mpeg4" : mencoderbat.s=mencoderbat.s+"--encoder ffmpeg " : EndIf
  If GetGadgetText(#videocodec)="X264"
    mencoderbat.s=mencoderbat.s+"--encoder x264 "
    If ReadFile(777,here.s+"menprofile.txt")
      While Eof(777) = #False
        line.s = LCase(ReadString(777))
        If FindString(line.s,"x264-handbrake",0) And FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0)
          encostring.s=StringField(line.s,4,";")
        EndIf
      Wend
      CloseFile(777)
    EndIf
    
    encostring.s=ReplaceString(encostring.s,"-ovc x264 -x264encopts bitrate:threads=auto:","")
    mencoderbat.s=mencoderbat.s+"--encopts "+encostring.s+" "
    
  EndIf
  
  If GetGadgetText(#pass)="1 pass" : mencoderbat.s=mencoderbat.s+"--vb "+GetGadgetText(#videokbits)+" " : EndIf
  If GetGadgetText(#pass)="2 pass" : mencoderbat.s=mencoderbat.s+"--turbo --two-pass --size "+GetGadgetText(#cds)+" " : EndIf
  If GetGadgetText(#pass)="CRF 1 pass" : mencoderbat.s=mencoderbat.s+"--quality "+GetGadgetText(#videokbits)+" " : EndIf
  If GetGadgetText(#pass)="Copy Video" : mencoderbat.s=mencoderbat.s+"--quality 1 " : EndIf
  
  
  If GetGadgetText(#mdeint)="FILM NTSC (29.97->23.976)" : mencoderbat.s=mencoderbat.s+"--detelecine " : EndIf
  If GetGadgetText(#mdeint)="Interlaced" : mencoderbat.s=mencoderbat.s+"--deinterlace " : EndIf
  If GetGadgetText(#mdeint)="Telecine" : mencoderbat.s=mencoderbat.s+"--detelecine " : EndIf
  If GetGadgetText(#mdeint)="Mixed Prog/Telecine" : mencoderbat.s=mencoderbat.s+"--detelecine " : EndIf
  If GetGadgetText(#mdeint)="Mixed Prog/Interlaced" : mencoderbat.s=mencoderbat.s+"--deinterlace " : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 23.976" : mencoderbat.s=mencoderbat.s+"--rate 23.976 " : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 25" : mencoderbat.s=mencoderbat.s+"--rate 25 " : EndIf
  If GetGadgetText(#mdeint)="Change FPS to 29.97" : mencoderbat.s=mencoderbat.s+"--rate 29.97 " : EndIf
  
  If GetGadgetText(#audiotrack)<>"none"
    mencoderbat.s=mencoderbat.s+"--audio "+Str(GetGadgetState(#audiotrack))+" "
    If GetGadgetText(#audiocodec)="MP3 Audio" : mencoderbat.s=mencoderbat.s+"--aencoder lame " : EndIf
    If GetGadgetText(#audiocodec)="AAC Audio" : mencoderbat.s=mencoderbat.s+"--aencoder faac " : EndIf
    If GetGadgetText(#audiocodec)="AC3 Audio" : mencoderbat.s=mencoderbat.s+"--aencoder ac3 " : EndIf
    If GetGadgetText(#audiocodec)="OGG Audio" : mencoderbat.s=mencoderbat.s+"--aencoder vorbis " : EndIf
    If GetGadgetText(#audiocodec)="Copy Audio" : mencoderbat.s=mencoderbat.s+"--aencoder ac3 " : EndIf
    
    If GetGadgetText(#audiocodec)<>"Copy Audio" And GetGadgetText(#audiocodec)<>"AC3 Audio"
      mencoderbat.s=mencoderbat.s+"--ab "+GetGadgetText(#audibit)+" "
      mencoderbat.s=mencoderbat.s+"--mixdown "+GetGadgetText(#channel)+" "
      
      If GetGadgetText(#sampling)="48000" : mencoderbat.s=mencoderbat.s+"--arate 48000 " : EndIf
      If GetGadgetText(#sampling)="44100" : mencoderbat.s=mencoderbat.s+"--arate 44100 " : EndIf
      If GetGadgetText(#sampling)="24000" : mencoderbat.s=mencoderbat.s+"--arate 24000 " : EndIf
      If GetGadgetText(#sampling)="22050" : mencoderbat.s=mencoderbat.s+"--arate 22050 " : EndIf
      If GetGadgetState(#audionormalize)=1 : mencoderbat.s=mencoderbat.s+"--drc 2.0 " : EndIf
    EndIf
    
  EndIf
  
  If GetGadgetState(#allowresize)=1
    mencoderbat.s=mencoderbat.s+"-w "+GetGadgetText(#width)+" "
    mencoderbat.s=mencoderbat.s+"-l "+GetGadgetText(#height)+" "
    If GetGadgetText(#bottomcrop)<>"" Or GetGadgetText(#topcrop)<>"" Or GetGadgetText(#leftcrop)<>"" Or GetGadgetText(#rightcrop)<>""
      mencoderbat.s=mencoderbat.s+"--crop "+GetGadgetText(#topcrop)+":"+GetGadgetText(#bottomcrop)+":"+GetGadgetText(#leftcrop)+":"+GetGadgetText(#rightcrop)+" "
    EndIf
  EndIf
  
  ;If windows=#true : mencoderbat.s=mencoderbat.s+"-p " : EndIf
  If GetGadgetText(#denoise)="Super Light" : mencoderbat.s=mencoderbat.s+"--denoise weak " : EndIf
  If GetGadgetText(#denoise)="Light" : mencoderbat.s=mencoderbat.s+"--denoise weak " : EndIf
  If GetGadgetText(#denoise)="Normal" : mencoderbat.s=mencoderbat.s+"--denoise medium " : EndIf
  If GetGadgetText(#denoise)="Severe" : mencoderbat.s=mencoderbat.s+"--denoise strong " : EndIf
  
  AddGadgetItem(#queue,-1,mencoderbat.s)
  
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    
    If GetGadgetState(#shutdown)=1
      If linux=#True : AddGadgetItem(#queue,-1,"shutdown now") : EndIf
      If windows=#True : AddGadgetItem(#queue,-1,"shutdown -s -t 30 -f") : EndIf
    EndIf
    
  EndIf
  
  
  If queue.l=0
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
      CreateFile(666,here.s+"automen.bat")
      WriteStringN(666,"")
      WriteStringN(666,GetGadgetText(#queue))
      CloseFile(666)
      If linux=#True
        RunProgram("chmod","+x "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s,#PB_Program_Wait)
        RunProgram("xterm","-e "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s)
      Else
        RunProgram(here.s+"automen.bat","",here.s)
      EndIf
      ClearGadgetItems(#queue)
    EndIf
  EndIf
  
  
EndProcedure



Procedure x264demuxer()
  
  mux.s=""
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="ifo"
    dump.s=mplayer.s+" dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(GetGadgetText(#inputstring)),0,Len(GetPathPart(GetGadgetText(#inputstring)))-1)+Chr(34)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34)
    
    AddGadgetItem(#queue,0,dump.s)
    inputfile.s=workpath.s+"film.vob"
  EndIf
  
  If linux=#True : mencoderbat.s="x264 "+Chr(34)+inputfile.s+Chr(34)+" " : EndIf
  If windows=#True : mencoderbat.s=Chr(34)+here.s+"applications\x264.exe"+Chr(34)+" "+Chr(34)+inputfile.s+Chr(34)+" " : EndIf
  
  If ReadFile(777,here.s+"menprofile.txt")
    While Eof(777) = #False
      line.s = LCase(ReadString(777))
      If FindString(line.s,"avisynth-x264",0) And FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0)
        encostring.s=StringField(line.s,4,";")
      EndIf
    Wend
    CloseFile(777)
  EndIf
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=2 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"automen.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"automen.stats"+Chr(34)+" " : EndIf
  If passx.l=5 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=7 : encostring.s=encostring.s+" --crf 18 " : EndIf
  
  If passx.l=8 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  
  If passx.l=10 : encostring.s=encostring.s+" --bitrate %bitrate% " : EndIf
  
  If GetGadgetState(#allowresize)=1
    encostring.s=encostring.s+"--video-filter crop:"+Str(leftcrop.l)+","+Str(topcrop.l)+","+Str(rightcrop.l)+","+Str(bottomcrop.l)+"/resize:"+Str(width.l)+","+Str(height.l)+",method="+LCase(StringField(GetGadgetText(#resizer),2," "))
  EndIf
  
  If GetGadgetText(#mdeint)="Progressive" : encostring.s=encostring.s+" --no-interlaced ": EndIf
  If GetGadgetText(#mdeint)="Interlaced" : encostring.s=encostring.s+" --no-interlaced ": EndIf
  
  
  If GetGadgetText(#container)="MKV" Or GetGadgetText(#container)="MP4" Or GetGadgetText(#container)="H264"
    outputfile.s="automen_x264.h264"
  EndIf
  
  If GetGadgetText(#container)="FLV"
    outputfile.s="automen_x264.flv"
  EndIf
  
  mencoderbat.s=mencoderbat.s+encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)
  
  If passx.l=8 : mencoderbat.s=mencoderbat.s+" 2>temp.txt" : EndIf
  
  If GetGadgetText(#audiotrack)<>"none"
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
      
      AddGadgetItem(#queue,-1,mencoderbat.s)
      
      mencoderbat.s=Chr(34)+GetGadgetText(#pathtomencoder)+Chr(34)+" "
      
      mencoderbat.s=mencoderbat.s+"-lavdopts threads=1 -lavcopts threads=1 -mc 0 -noskip "
      
      If FindString(GetGadgetText(#audiotrack),"audio stream:",0) And FindString(GetGadgetText(#audiotrack),"language:",0)
        mencoderbat.s=mencoderbat.s+"-aid "+StringField(GetGadgetText(#audiotrack),CountString(GetGadgetText(#audiotrack),":")+1,":")+" "
      EndIf
      
      If FindString(GetGadgetText(#audiotrack),"ID_AUDIO_ID",0)
        mencoderbat.s=mencoderbat.s+"-aid "+StringField(GetGadgetText(#audiotrack),2,"=")+" "
        
        If LCase(GetExtensionPart(inputfile.s))="mkv"
          mencoderbat.s=mencoderbat.s+"-aid "+StringField(StringField(StringField(GetGadgetText(#audiotrack),2,"-"),2," "),1,",")+" "
        EndIf
        
        If LCase(GetExtensionPart(inputfile.s))<>"ifo"
          mencoderbat.s=mencoderbat.s+" "+Chr(34)+inputfile.s+Chr(34)+" -ovc frameno "
        EndIf
        
        
        If LCase(GetExtensionPart(inputfile.s))="ifo"
          inputfile.s="dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(inputfile.s),0,Len(GetPathPart(inputfile.s))-1)+Chr(34)
          mencoderbat.s=mencoderbat.s+" "+inputfile.s+" -ovc frameno "
        EndIf
        
        If GetGadgetState(#audionormalize)=1 : mencoderbat.s=mencoderbat.s+" -af volnorm=1 " : EndIf
        If GetGadgetText(#audiocodec)="MP3 Audio" : mencoderbat.s=mencoderbat.s+" -oac mp3lame -lameopts "+GetGadgetText(#mp3mode)+":br="+GetGadgetText(#audibit)+" " : EndIf
        If GetGadgetText(#audiocodec)="AAC Audio" : mencoderbat.s=mencoderbat.s+" -oac faac -faacopts br="+GetGadgetText(#audibit)+":mpeg=4:tns:object=2 " : EndIf
        If GetGadgetText(#audiocodec)="OGG Audio" : mencoderbat.s=mencoderbat.s+" -oac lavc -lavcopts acodec=vorbis:abitrate="+GetGadgetText(#audibit)+" " : EndIf
        If GetGadgetText(#audiocodec)="AC3 Audio" : mencoderbat.s=mencoderbat.s+" -oac lavc -lavcopts acodec=ac3:abitrate="+GetGadgetText(#audibit)+" " : EndIf
        If GetGadgetText(#audiocodec)="Copy Audio" : mencoderbat.s=mencoderbat.s+" -oac copy " : EndIf
        
        If GetGadgetText(#channel)="1" : mencoderbat.s=mencoderbat.s+" -channels 1 " : EndIf
        If GetGadgetText(#channel)="2" : mencoderbat.s=mencoderbat.s+" -channels 2 " : EndIf
        If GetGadgetText(#channel)="Original" : mencoderbat.s=mencoderbat.s+" " : EndIf
        
        mencoderbat.s=mencoderbat.s+" -of rawaudio -o "
        If GetGadgetText(#audiocodec)="MP3 Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".mp3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AAC Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".aac"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="OGG Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".ogg"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AC3 Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".ac3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="Copy Audio"
          If FindString(LCase(GetGadgetText(#audiotrack)),"ac3",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".ac3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"dts",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".dts"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"mp3",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".mp3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"aac",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".aac"+Chr(34) : EndIf
        EndIf
        
      EndIf
      
    EndIf
  EndIf
  
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    mux.s=""
    
    If GetGadgetText(#mdeint)="FILM NTSC (29.97->23.976)" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Telecine" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Mixed Prog/Telecine" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Change FPS to 23.976" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Change FPS to 25" : framerate.f=25 : EndIf
    If GetGadgetText(#mdeint)="Change FPS to 29.97" : framerate.f=29.97 : EndIf
    
    If GetGadgetText(#container)="MKV"
      add.s=""
      mux.s=Chr(34)+mkvmerge.s+Chr(34)+" -o "+Chr(34)+GetGadgetText(#outputstring)+"_full.mkv"+Chr(34)+" --default-duration 0:"+StrF(framerate.f,3)+"fps "+Chr(34)+outputfile.s+Chr(34)
    EndIf
    
    If GetGadgetText(#container)="MP4"
      add.s="-add "
      mux.s=Chr(34)+mp4box.s+Chr(34)+" "+Chr(34)+GetGadgetText(#outputstring)+"_full.mp4"+Chr(34)+" -fps "+ StrF(framerate.f,3)+" -add "+Chr(34)+outputfile.s+Chr(34)
    EndIf
    
    If GetGadgetText(#audiotrack)<>"none"
      If GetGadgetText(#container)="MKV" Or GetGadgetText(#container)="MP4"
        If GetGadgetText(#audiocodec)="MP3 Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+"mp3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AAC Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+"aac"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="OGG Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+"ogg"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AC3 Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+"ac3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="Copy Audio"
          If FindString(LCase(GetGadgetText(#audiotrack)),"ac3",0) :  mux.s=mux.s+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".ac3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"dts",0) :  mux.s=mux.s+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".dts"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"mp3",0) :  mux.s=mux.s+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".mp3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"aac",0) :  mux.s=mux.s+add.s+" "+Chr(34)+Mid(outputfile.s,0,Len(outputfile.s)-4)+".aac"+Chr(34) : EndIf
        EndIf
      EndIf
    EndIf
    
    
  EndIf
  
  If passx.l=9
    mencoderbat.s="FOR /F "+Chr(34)+"tokens=7 delims=. "+Chr(34)+" %%A IN ('findstr encoded temp.txt') DO SET bitrate=%%A"
  EndIf
  
  AddGadgetItem(#queue,-1,mencoderbat.s)
  
  
  If mux.s<>""
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
      AddGadgetItem(#queue,-1,mux.s)
    EndIf
  EndIf
  
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    
    If GetGadgetState(#shutdown)=1
      If linux=#True : AddGadgetItem(#queue,-1,"shutdown now") : EndIf
      If windows=#True : AddGadgetItem(#queue,-1,"shutdown -s -t 30 -f") : EndIf
    EndIf
    
  EndIf
  
  
  If queue.l=0
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7 Or passx.l=10
      CreateFile(666,here.s+"automen.bat")
      WriteStringN(666,"")
      WriteStringN(666,GetGadgetText(#queue))
      CloseFile(666)
      If linux=#True
        RunProgram("chmod","+x "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s,#PB_Program_Wait)
        RunProgram("xterm","-e "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s)
      Else
        RunProgram(here.s+"automen.bat","",here.s)
      EndIf
      ClearGadgetItems(#queue)
    EndIf
  EndIf
  
EndProcedure

Procedure  x264avs()
  
  mux.s=""
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="ifo"
    dump.s=mplayer.s+" dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(GetGadgetText(#inputstring)),0,Len(GetPathPart(GetGadgetText(#inputstring)))-1)+Chr(34)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34)
    
    AddGadgetItem(#queue,0,dump.s)
    inputfile.s=workpath.s+"film.vob"
  EndIf
  
  
  If linux=#True : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  CreateFile(987,workpath.s+"automen.avs")
  
  If ExamineDirectory(0,here+"filters\","*.dll")
    Repeat
      type=NextDirectoryEntry(0)
      If type=1 ; File
        a$=LCase(DirectoryEntryName(0))
        If FindString(a$,"soundout",0)=0
          If FindString(a$,"yadif",0)=0
            WriteStringN(987,"LoadPlugin("+Chr(34)+here+"filters\"+a$+Chr(34)+")")
          EndIf
        EndIf
        If FindString(LCase(a$),"yadif",0)<>0
          WriteStringN(987,"LoadCPlugin("+Chr(34)+here+"filters\"+a$+Chr(34)+")")
        EndIf
      EndIf
    Until type=0
  EndIf
  
  If ExamineDirectory(0,here+"filters\","*.avsi")
    Repeat
      type=NextDirectoryEntry(0)
      If type=1 ; File
        a$=DirectoryEntryName(0)
        WriteStringN(987,"Import("+Chr(34)+here+"filters\"+a$+Chr(34)+")")
      EndIf
    Until type=0
  EndIf
  
 Select LCase(GetExtensionPart(inputfile.s))
      
    Case "vob","avi","mpeg","m2v","mpg","ogm","vro","mkv"
      WriteStringN(987,"Try {")
      WriteStringN(987,"FFVideoSource("+Chr(34)+inputfile.s+Chr(34)+", track = -1, cache = false, seekmode = 0)")
      WriteStringN(987,"}")
      WriteStringN(987,"Catch(Err_Msg) {")
      WriteStringN(987,"DirectShowSource("+Chr(34)+inputfile.s+Chr(34)+",audio=false)")
      WriteStringN(987,"}")
    Case "evo","ts","grf","m2t","mov","mp4","m2ts"
      WriteStringN(987,"Try {")
      WriteStringN(987,"DirectShowSource("+Chr(34)+inputfile.s+Chr(34)+",audio=false)")
      WriteStringN(987,"}")
      WriteStringN(987,"Catch(Err_Msg) {")
      WriteStringN(987,"FFVideoSource("+Chr(34)+inputfile.s+Chr(34)+", track = -1, cache = false, seekmode = 0)")
      WriteStringN(987,"}")
    Case "avs"
      WriteStringN(987,"Import("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "d2v"
      WriteStringN(987,"Mpeg2Source("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "dgm","dgv"
      WriteStringN(987,"DGSource("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "dga"
      WriteStringN(987,"AVCSource("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "dgi"
      WriteStringN(987,"DGSource("+Chr(34)+inputfile.s+Chr(34)+")")
    Default
      WriteStringN(987,"Try {")
      WriteStringN(987,"DirectShowSource("+Chr(34)+inputfile.s+Chr(34)+",audio=false)")
      WriteStringN(987,"}")
      WriteStringN(987,"Catch(Err_Msg) {")
      WriteStringN(987,"FFVideoSource("+Chr(34)+inputfile.s+Chr(34)+", track = -1, cache = false, seekmode = 0)")
      WriteStringN(987,"}")
      
    EndSelect
  
  Select GetGadgetText(#mdeint)
  Case "FILM NTSC (29.97->23.976)","Telecine","Mixed Prog/Telecine"
    
    If GetExtensionPart(inputfile.s)<>"d2v"
      WriteStringN(987,"tfm(last).tdecimate()")
    EndIf
    If GetExtensionPart(inputfile.s)="d2v"
      WriteStringN(987,"tfm(d2v="+Chr(34)+inputfile.s+Chr(34)+").tdecimate()")
    EndIf
    
  Case "Interlaced"
    WriteStringN(987,"Yadif(mode=0,order=-1)")
  Case "Mixed Prog/Interlaced"
    WriteStringN(987,"TDeint(mode=0,order=-1)")
  Case "Change FPS to 23.976"
    WriteStringN(987,"ChangeFPS(23.976)")
  Case "Change FPS to 25"
    WriteStringN(987,"ChangeFPS(25.000)")
  Case "Change FPS to 29.97"
    WriteStringN(987,"ChangeFPS(29.97)")
  EndSelect
  
  leftcrop.l=Val(GetGadgetText(#leftcrop))
  topcrop.l=Val(GetGadgetText(#topcrop))
  rightcrop.l=Val(GetGadgetText(#rightcrop))
  bottomcrop.l=Val(GetGadgetText(#bottomcrop))
  
  If GetGadgetState(#allowresize)=1
    width.l=Val(GetGadgetText(#width))
    height.l=Val(GetGadgetText(#height))
    
    If width.l<>0 And height.l<>0
      
      Select GetGadgetState(#resizer)
      Case 1
        WriteStringN(987,"PointResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 2
        WriteStringN(987,"BilinearResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 3
        WriteStringN(987,"BicubicResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 4
        WriteStringN(987,"LanczosResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 5
        WriteStringN(987,"Lanczos4Resize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 6
        WriteStringN(987,"Spline16Resize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 7
        WriteStringN(987,"Spline36Resize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 8
        WriteStringN(987,"Spline64Resize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Case 9,10
        WriteStringN(987,"BlackmanResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      Default
        WriteStringN(987,"LanczosResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
      EndSelect
      
    EndIf
    
  EndIf
  
  Select GetGadgetText(#denoise)
  Case "Super Light"
    WriteStringN(987,"Hqdn3d(1)")
  Case "Light"
    WriteStringN(987,"Hqdn3d(2)")
  Case "Normal"
    WriteStringN(987,"Hqdn3d(4)")
  Case "Severe"
    WriteStringN(987,"Hqdn3d(6)")
  EndSelect
  
  If FindString(GetGadgetText(#subs),"/",0) Or FindString(GetGadgetText(#subs),"\",0)
    If FindString(LCase(GetGadgetText(#subs)),".srt",0) : WriteStringN(987,"TextSub("+Chr(34)+GetGadgetText(#subs)+Chr(34)+")") : EndIf
    If FindString(LCase(GetGadgetText(#subs)),".utf8",0) : WriteStringN(987,"TextSub("+Chr(34)+GetGadgetText(#subs)+Chr(34)+")") : EndIf
    If FindString(LCase(GetGadgetText(#subs)),".idx",0) : WriteStringN(987,"VobSub("+Chr(34)+GetGadgetText(#subs)+Chr(34)+")") : EndIf
    If FindString(LCase(GetGadgetText(#subs)),".ssa",0) : WriteStringN(987,"TextSub("+Chr(34)+GetGadgetText(#subs)+Chr(34)+")") : EndIf
    If FindString(LCase(GetGadgetText(#subs)),".ass",0) : WriteStringN(987,"TextSub("+Chr(34)+GetGadgetText(#subs)+Chr(34)+")") : EndIf
  EndIf
  
  CloseFile(987)
  
  mencoderbat.s=Chr(34)+here.s+"applications\x264.exe"+Chr(34)+" "+Chr(34)+workpath.s+"automen.avs"+Chr(34)+" "
  
  If ReadFile(777,here.s+"menprofile.txt")
    While Eof(777) = #False
      line.s = LCase(ReadString(777))
      If FindString(line.s,"avisynth-x264",0) And FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0)
        encostring.s=StringField(line.s,4,";")
      EndIf
    Wend
    CloseFile(777)
  EndIf
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=2 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+workpath.s+"automen.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+workpath.s+"automen.stats"+Chr(34)+" " : EndIf
  If passx.l=5 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=7 : encostring.s=encostring.s+" --crf 18 " : EndIf
  
  If passx.l=8 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  
  If passx.l=10 : encostring.s=encostring.s+" --bitrate %bitrate% " : EndIf
  
  If GetGadgetText(#container)="MKV" Or GetGadgetText(#container)="MP4" Or GetGadgetText(#container)="H264"
    outputfile.s="video.h264"
  EndIf
  
  If GetGadgetText(#container)="FLV"
    outputfile.s=GetFilePart(GetGadgetText(#outputstring))
  EndIf
  
  mencoderbat.s=mencoderbat.s+encostring.s+" --output "+Chr(34)+workpath.s+outputfile.s+Chr(34)
  
  If passx.l=8 : mencoderbat.s=mencoderbat.s+" 2>temp.txt" : EndIf
  
  
  If GetGadgetText(#audiotrack)<>"none"
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
      
      AddGadgetItem(#queue,-1,mencoderbat.s)
      
      mencoderbat.s=Chr(34)+GetGadgetText(#pathtomencoder)+Chr(34)+" "
      
      mencoderbat.s=mencoderbat.s+"-lavdopts threads=1 -lavcopts threads=1 -mc 0 -noskip "
      
      If FindString(GetGadgetText(#audiotrack),"audio stream:",0) And FindString(GetGadgetText(#audiotrack),"language:",0)
        mencoderbat.s=mencoderbat.s+"-aid "+StringField(GetGadgetText(#audiotrack),CountString(GetGadgetText(#audiotrack),":")+1,":")+" "
      EndIf
      
      If FindString(GetGadgetText(#audiotrack),"ID_AUDIO_ID",0)
        mencoderbat.s=mencoderbat.s+"-aid "+StringField(GetGadgetText(#audiotrack),2,"=")+" "
        
        If LCase(GetExtensionPart(inputfile.s))="mkv"
          mencoderbat.s=mencoderbat.s+"-aid "+StringField(StringField(StringField(GetGadgetText(#audiotrack),2,"-"),2," "),1,",")+" "
        EndIf
        
        If LCase(GetExtensionPart(inputfile.s))<>"ifo"
          mencoderbat.s=mencoderbat.s+" "+Chr(34)+inputfile.s+Chr(34)+" -ovc frameno "
        EndIf
        
        
        If LCase(GetExtensionPart(inputfile.s))="ifo"
          inputfile.s="dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(inputfile.s),0,Len(GetPathPart(inputfile.s))-1)+Chr(34)
          mencoderbat.s=mencoderbat.s+" "+inputfile.s+" -ovc frameno "
        EndIf
        
        If GetGadgetState(#audionormalize)=1 : mencoderbat.s=mencoderbat.s+" -af volnorm=1 " : EndIf
        If GetGadgetText(#audiocodec)="MP3 Audio" : mencoderbat.s=mencoderbat.s+" -oac mp3lame -lameopts "+GetGadgetText(#mp3mode)+":br="+GetGadgetText(#audibit)+" " : EndIf
        If GetGadgetText(#audiocodec)="AAC Audio" : mencoderbat.s=mencoderbat.s+" -oac faac -faacopts br="+GetGadgetText(#audibit)+":mpeg=4:tns:object=2 " : EndIf
        If GetGadgetText(#audiocodec)="OGG Audio" : mencoderbat.s=mencoderbat.s+" -oac lavc -lavcopts acodec=vorbis:abitrate="+GetGadgetText(#audibit)+" " : EndIf
        If GetGadgetText(#audiocodec)="AC3 Audio" : mencoderbat.s=mencoderbat.s+" -oac lavc -lavcopts acodec=ac3:abitrate="+GetGadgetText(#audibit)+" " : EndIf
        If GetGadgetText(#audiocodec)="Copy Audio" : mencoderbat.s=mencoderbat.s+" -oac copy " : EndIf
        
        If GetGadgetText(#channel)="1" : mencoderbat.s=mencoderbat.s+" -channels 1 " : EndIf
        If GetGadgetText(#channel)="2" : mencoderbat.s=mencoderbat.s+" -channels 2 " : EndIf
        If GetGadgetText(#channel)="Original" : mencoderbat.s=mencoderbat.s+" " : EndIf
        
        mencoderbat.s=mencoderbat.s+" -of rawaudio -o "
        If GetGadgetText(#audiocodec)="MP3 Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.mp3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AAC Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.aac"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="OGG Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.ogg"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AC3 Audio" : mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.ac3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="Copy Audio"
          If FindString(LCase(GetGadgetText(#audiotrack)),"ac3",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.ac3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"dts",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.dts"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"mp3",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.mp3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"aac",0) :  mencoderbat.s=mencoderbat.s+Chr(34)+workpath.s+"audio.aac"+Chr(34) : EndIf
        EndIf
        
      EndIf
      
    EndIf
    
  EndIf
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    mux.s=""
    
    If GetGadgetText(#mdeint)="FILM NTSC (29.97->23.976)" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Telecine" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Mixed Prog/Telecine" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Change FPS to 23.976" : framerate.f=23.976 : EndIf
    If GetGadgetText(#mdeint)="Change FPS to 25" : framerate.f=25 : EndIf
    If GetGadgetText(#mdeint)="Change FPS to 29.97" : framerate.f=29.97 : EndIf
    
    If GetGadgetText(#container)="MKV"
      add.s=""
      mux.s=Chr(34)+mkvmerge.s+Chr(34)+" -o "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)+" --default-duration 0:"+StrF(framerate.f,3)+"fps "+Chr(34)+workpath.s+"video.h264"+Chr(34)
    EndIf
    
    If GetGadgetText(#container)="MP4"
      add.s="-add "
      mux.s=Chr(34)+mp4box.s+Chr(34)+" "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)+" -add "+Chr(34)+workpath.s+"video.h264"+Chr(34)
    EndIf
    
    
    If GetGadgetText(#audiotrack)<>"none"
      If GetGadgetText(#container)="MKV" Or GetGadgetText(#container)="MP4"
        If GetGadgetText(#audiocodec)="MP3 Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.mp3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AAC Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.aac"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="OGG Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.ogg"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="AC3 Audio" : mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.ac3"+Chr(34) : EndIf
        If GetGadgetText(#audiocodec)="Copy Audio"
          If FindString(LCase(GetGadgetText(#audiotrack)),"ac3",0) :  mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.ac3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"dts",0) :  mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.dts"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"mp3",0) :  mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.mp3"+Chr(34) : EndIf
          If FindString(LCase(GetGadgetText(#audiotrack)),"aac",0) :  mux.s=mux.s+" "+add.s+" "+Chr(34)+workpath.s+"audio.aac"+Chr(34) : EndIf
        EndIf
      EndIf
    EndIf
    
  EndIf
  
  If passx.l=9
    mencoderbat.s="FOR /F "+Chr(34)+"tokens=7 delims=. "+Chr(34)+" %%A IN ('findstr encoded temp.txt') DO SET bitrate=%%A"
  EndIf
  
  AddGadgetItem(#queue,-1,mencoderbat.s)
  
  
  If mux.s<>""
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
      AddGadgetItem(#queue,-1,mux.s)
    EndIf
  EndIf
  
  
  If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
    
    If GetGadgetState(#shutdown)=1
      If linux=#True : AddGadgetItem(#queue,-1,"shutdown now") : EndIf
      If windows=#True : AddGadgetItem(#queue,-1,"shutdown -s -t 30 -f") : EndIf
    EndIf
    
  EndIf
  
  If queue.l=0
    If passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=7
      CreateFile(666,workpath.s+"automen.bat")
      WriteStringN(666,"")
      WriteStringN(666,GetGadgetText(#queue))
      CloseFile(666)
      If linux=#True
        RunProgram("chmod","+x "+Chr(34)+workpath.s+"automen.bat"+Chr(34),workpath.s,#PB_Program_Wait)
        RunProgram("xterm","-e "+Chr(34)+workpath.s+"automen.bat"+Chr(34),workpath.s)
      Else
        RunProgram(workpath.s+"automen.bat","",workpath.s)
      EndIf
      ClearGadgetItems(#queue)
    EndIf
  EndIf
  
EndProcedure


Procedure start()
  
  
  If GetGadgetText(#encodewith)="Mencoder for Encoding" : mencoder() : EndIf
  
  If GetGadgetText(#encodewith)="Use AviSynth (only for X264)" : x264avs() : EndIf
  
  If GetGadgetText(#encodewith)="Use X264 as demuxer and encoder" : x264demuxer() : EndIf
  
  If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding" : handbrake() : EndIf
  
  If GetGadgetText(#encodewith)="Use ffmpeg as encoder" : ffmpeg() : EndIf
  
EndProcedure

Procedure startqueue()
  
  CreateFile(666,here.s+"automen.bat")
  WriteStringN(666,"")
  WriteStringN(666,GetGadgetText(#queue))
  CloseFile(666)
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"automen.bat"+Chr(34),here.s)
  Else
    RunProgram(here.s+"automen.bat","",here.s)
  EndIf
  ClearGadgetItems(#queue)
  
EndProcedure


Procedure parseprofile()
  
  
  If GetGadgetText(#encodewith)="Mencoder for Encoding"
    countprofile.l=0
    ReadFile(888,here.s+"menprofile.txt")
    While Eof(888) = 0
      line.s = LCase(ReadString(888))
      
      If GetGadgetText(#videocodec)="XviD" And FindString(line.s,"mencoder-xvid",0)
        countprofile.l=countprofile.l+1
      EndIf
      If GetGadgetText(#videocodec)="Mpeg4" And FindString(line.s,"mencoder-mpeg4",0)
        countprofile.l=countprofile.l+1
      EndIf
      If GetGadgetText(#videocodec)="X264" And FindString(line.s,"mencoder-x264",0)
        countprofile.l=countprofile.l+1
      EndIf
    Wend
    CloseFile(888)
    SetGadgetAttribute(#speedquality, #PB_TrackBar_Maximum ,countprofile.l)
  EndIf
  
  If GetGadgetText(#encodewith)="Use ffmpeg as encoder"
    countprofile.l=0
    ReadFile(888,here.s+"menprofile.txt")
    While Eof(888) = 0
      line.s = LCase(ReadString(888))
      
      If GetGadgetText(#videocodec)="XviD" And FindString(line.s,"ffmpeg-xvid",0)
        countprofile.l=countprofile.l+1
      EndIf
      If GetGadgetText(#videocodec)="Mpeg4" And FindString(line.s,"ffmpeg-mpeg4",0)
        countprofile.l=countprofile.l+1
      EndIf
      If GetGadgetText(#videocodec)="X264" And FindString(line.s,"ffmpeg-x264",0)
        countprofile.l=countprofile.l+1
      EndIf
      If GetGadgetText(#videocodec)="WMV" And FindString(line.s,"ffmpeg-wmv",0)
        countprofile.l=countprofile.l+1
      EndIf
    Wend
    CloseFile(888)
    SetGadgetAttribute(#speedquality, #PB_TrackBar_Maximum ,countprofile.l)
  EndIf
  
  If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding"
    countprofile.l=0
    ReadFile(888,here.s+"menprofile.txt")
    While Eof(888) = 0
      line.s = LCase(ReadString(888))
      
      If GetGadgetText(#videocodec)="Mpeg4" And FindString(line.s,"handbrake-ffmpeg4",0)
        countprofile.l=countprofile.l+1
      EndIf
      If GetGadgetText(#videocodec)="X264" And FindString(line.s,"handbrake-x264",0)
        countprofile.l=countprofile.l+1
      EndIf
    Wend
    CloseFile(888)
    SetGadgetAttribute(#speedquality, #PB_TrackBar_Maximum ,countprofile.l)
  EndIf
  
  If GetGadgetText(#encodewith)="Use AviSynth (only for X264)" Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder"
    countprofile.l=0
    ReadFile(888,here.s+"menprofile.txt")
    While Eof(888) = 0
      line.s = LCase(ReadString(888))
      If GetGadgetText(#videocodec)="X264" And FindString(line.s,"avisynth-x264",0)
        countprofile.l=countprofile.l+1
      EndIf
    Wend
    CloseFile(888)
    SetGadgetAttribute(#speedquality, #PB_TrackBar_Maximum ,countprofile.l)
  EndIf
  
  
  
  If ReadFile(888,here.s+"menprofile.txt")
    While Eof(888) = 0
      line.s = LCase(ReadString(888))
      
      If GetGadgetText(#encodewith)="Mencoder for Encoding"
        Debug(";"+Str(GetGadgetState(#speedquality))+";+++"+LCase(StringField(GetGadgetText(#videocodec),1," ")))
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,LCase(StringField(GetGadgetText(#videocodec),1," ")),0) And FindString(line.s,"mencoder",0)
          SetGadgetText(#speedqualitytext,StringField(GetGadgetText(#videocodec),1," ")+" "+StringField(line,3,";"))
        EndIf
      EndIf
      
      
      If GetGadgetText(#encodewith)="Use ffmpeg as encoder" And GetGadgetText(#videocodec)="WMV"
        Debug(";"+Str(GetGadgetState(#speedquality))+";+"+LCase(StringField(GetGadgetText(#videocodec),1," ")))
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,"ffmpeg-wmv",0)
          SetGadgetText(#speedqualitytext,StringField(GetGadgetText(#videocodec),1," ")+" "+StringField(line,3,";"))
        EndIf
      EndIf
      
      If GetGadgetText(#encodewith)="Use ffmpeg as encoder" And GetGadgetText(#videocodec)="X264"
        Debug(";"+Str(GetGadgetState(#speedquality))+";+"+LCase(StringField(GetGadgetText(#videocodec),1," ")))
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,"ffmpeg-x264",0)
          SetGadgetText(#speedqualitytext,StringField(GetGadgetText(#videocodec),1," ")+" "+StringField(line,3,";"))
        EndIf
      EndIf
      
      If GetGadgetText(#encodewith)="Use ffmpeg as encoder" And GetGadgetText(#videocodec)="XviD"
        Debug(";"+Str(GetGadgetState(#speedquality))+";+"+LCase(StringField(GetGadgetText(#videocodec),1," ")))
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,"ffmpeg-xvid",0)
          SetGadgetText(#speedqualitytext,StringField(GetGadgetText(#videocodec),1," ")+" "+StringField(line,3,";"))
        EndIf
      EndIf
      
      If GetGadgetText(#encodewith)="Use ffmpeg as encoder" And GetGadgetText(#videocodec)="Mpeg4"
        Debug(";"+Str(GetGadgetState(#speedquality))+";+"+LCase(StringField(GetGadgetText(#videocodec),1," ")))
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,"ffmpeg-mpeg4",0)
          SetGadgetText(#speedqualitytext,StringField(GetGadgetText(#videocodec),1," ")+" "+StringField(line,3,";"))
        EndIf
      EndIf
      
      If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding" And GetGadgetText(#videocodec)="X264"
        Debug(";"+Str(GetGadgetState(#speedquality))+";+"+LCase(StringField(GetGadgetText(#videocodec),1," ")))
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,"handbrake-x264",0)
          SetGadgetText(#speedqualitytext,StringField(GetGadgetText(#videocodec),1," ")+" "+StringField(line,3,";"))
        EndIf
      EndIf
      
      If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding" And GetGadgetText(#videocodec)="Mpeg4"
        Debug(";"+Str(GetGadgetState(#speedquality))+";+"+LCase(StringField(GetGadgetText(#videocodec),1," ")))
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,"handbrake-ffmpeg4",0)
          SetGadgetText(#speedqualitytext,StringField(GetGadgetText(#videocodec),1," ")+" "+StringField(line,3,";"))
        EndIf
      EndIf
      
      If GetGadgetText(#encodewith)="Use AviSynth (only for X264)" Or GetGadgetText(#encodewith)="Use X264 as demuxer and encoder"
        If FindString(line.s,";"+Str(GetGadgetState(#speedquality))+";",0) And FindString(line.s,"avisynth-x264",0)
          SetGadgetText(#speedqualitytext,"X264 "+StringField(line,3,";"))
        EndIf
      EndIf
      
    Wend
    CloseFile(888)
  EndIf
  
  
  
EndProcedure

Procedure Dimb()
  
  framecount.l=Val(GetGadgetText(#framecountf))
  tsec.l=framecount.l/(Val(GetGadgetText(#frameratef))+1)
  
  Dimb.f=Val(GetGadgetText(#cds))*1024*1024
  bitrate1.f=((Dimb.f-framecount.l*24-Val(GetGadgetText(#audibit))*1000*tsec.l*0.128)/((tsec.l*0.128)/1024)/1000)/1024
  
  
  If GetGadgetText(#audiocodec)="Copy Audio"
    abit.l=384
    If FindString(GetGadgetText(#audiotrack),"kb/s",0)
      For aa=1 To CountString(GetGadgetText(#audiotrack),",")+1
        mess.s=StringField(GetGadgetText(#audiotrack),aa,",")
        If FindString(mess.s,"kb/s",0)
          abit.l=Val(ReplaceString(mess.s,"kb/s",""))
        EndIf
      Next aa
    EndIf
    
    bitrate1.f=((Dimb.f-framecount.l*24-abit.l*1000*tsec.l*0.128)/((tsec.l*0.128)/1024)/1000)/1024
  EndIf
  
  
  If GetGadgetText(#audiocodec)="No Audio" Or GetGadgetText(#audiotrack)="none"
    bitrate1.f=((Dimb.f-framecount.l*24)/((tsec.l*0.128)/1024)/1000)/1024
  EndIf
  
  
  SetGadgetText(#videokbits,StrF(bitrate1.f,0))
  
  If bitrate1.f>10000 : SetGadgetColor(#videokbits,#PB_Gadget_BackColor,$0000FF) : EndIf
  
EndProcedure

Procedure preview()
  
  mess.s=""
  
  vcrop.s="crop="+Str(twidth.l-Val(GetGadgetText(#leftcrop))-Val(GetGadgetText(#rightcrop)))+":"+Str(theight.l-Val(GetGadgetText(#topcrop))-Val(GetGadgetText(#bottomcrop)))+":"+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)
  
  If LCase(GetExtensionPart(inputfile.s))<>"mkv"
    aid.s="-aid "+StringField(GetGadgetText(#audiotrack),2,"=")+" "
  Else
    aid.s="-aid "+StringField(StringField(StringField(GetGadgetText(#audiotrack),2,"-"),2," "),1,",")+" "
  EndIf
  
  
  If LCase(GetExtensionPart(inputfile.s))="ifo"
    aid.s="-aid "+Trim(StringField(GetGadgetText(#audiotrack),CountString(GetGadgetText(#audiotrack),":")+1,":"))
  EndIf
  
  If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding"
    aid.s=""
  EndIf
  
  CreateFile(987,here.s+"mplayerpreview.bat")
  WriteString(987,mplayer.s+" "+aid.s+" -vf "+vcrop.s+",scale="+GetGadgetText(#width)+":"+GetGadgetText(#height)+" -aspect "+GetGadgetText(#arcombo)+" "+Chr(34)+inputfile.s+Chr(34))
  CloseFile(987)
  
  RunProgram(mplayer.s," "+aid.s+" -vf "+vcrop.s+",scale="+GetGadgetText(#width)+":"+GetGadgetText(#height)+" -aspect "+GetGadgetText(#arcombo)+" "+Chr(34)+inputfile.s+Chr(34),here.s)
  
EndProcedure

Procedure autocrop()
  
  DeleteFile(here.s+"mplayer_deep.bat")
  DeleteFile(here.s+"mplayer_deep.log")
  
  If FileSize(GetGadgetText(#pathtomplayer))=-1
    MessageRequester("AutoMen","No mplayer found"+Chr(13)+Chr(13)+"Please download/install mplayer")
    ProcedureReturn
  EndIf
  
  acbottom.l=0
  acleft.l=0
  cropright.l=0
  actop.l=0
  mess.s=""
  mess1.s=""
  vcrop.s=""
  
  
  CreateFile(987,here.s+"mplayer_deep.bat")
  
  If linux=#True
    WriteString(987,mplayer.s+" -speed 100 -vo null -vf cropdetect=24:2 -nosound -frames 2500 -identify "+Chr(34)+inputfile.s+Chr(34)+" > mplayer_deep.log")
  EndIf
  
  If windows=#True
    WriteString(987,mplayer.s+" -speed 100 -vo null -vf cropdetect=24:2 -nosound -frames 2500 -identify "+Chr(34)+inputfile.s+Chr(34)+" 1>mplayer_deep.log 2>automen.log")
  EndIf
  
  CloseFile(987)
  
  If windows=#True
    RunProgram(here.s+"mplayer_deep.bat","",here.s,#PB_Program_Wait)
  EndIf
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"mplayer_deep.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"mplayer_deep.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  
  If OpenFile(fh,here.s+"mplayer_deep.log")
    While Eof(fh)=0
      mess.s=ReadString(fh)
      If FindString(mess.s,"-vf crop=",0)
        vcrop.s=StringField(mess.s,2,"=")
        vcrop.s=StringField(vcrop.s,1,")")
        Debug("crop="+vcrop.s)
      EndIf
    Wend
  EndIf
  CloseFile(fh)
  
  ;crop=720:432:0:72
  ;crop=688:560:4:8
  actop.l=theight.l-Val(StringField(vcrop.s,2,":"))-Val(StringField(vcrop.s,4,":"))
  acleft.l=Val(StringField(vcrop.s,3,":"))
  acright.l=twidth.l-acleft.l-Val(StringField(vcrop.s,1,":"))
  acbottom.l=theight.l-(Val(StringField(vcrop.s,2,":"))+actop.l)
  Debug(" -cropleft "+Str(acleft.l)+" -croptop "+Str(actop.l)+" -cropright "+Str(acright.l)+" -cropbottom "+Str(acbottom.l)+" " )
  
  SetGadgetText(#bottomcrop,"")
  SetGadgetText(#leftcrop,"")
  SetGadgetText(#rightcrop,"")
  SetGadgetText(#topcrop,"")
  
  If actop.l>145 Or acbottom.l>145 Or acleft.l>145 Or acright.l>145
    
    If actop.l=theight.l Or acright.l=twidth.l
      actop.l=0
      acright.l=0
    EndIf
    
    MessageRequester("AutoCrop", "Please, check autocrop value", #PB_MessageRequester_Ok )
  EndIf
  
  SetGadgetText(#bottomcrop,Str(acbottom.l))
  SetGadgetText(#leftcrop,Str(acleft.l))
  SetGadgetText(#rightcrop,Str(acright.l))
  SetGadgetText(#topcrop,Str(actop.l))
  
EndProcedure

Procedure silentscale()
  
  Delay(1)
  acbottom.l=Val(GetGadgetText(#bottomcrop))
  acleft.l=Val(GetGadgetText(#leftcrop))
  acright.l=Val(GetGadgetText(#rightcrop))
  actop.l=Val(GetGadgetText(#topcrop))
  
  Debug(twidth.l)
  Debug(theight.l)
  Debug(framerate.f)
  Debug(tsec.l)
  Debug(ar.s)
  Debug(acleft.l)
  Debug(acright.l)
  Debug(actop.l)
  Debug(acbottom.l)
  
  aspectinfo.f=ValF(GetGadgetText(#arcombo))
  
  If GetGadgetState(#itu)=1 : itu.f=53.3333/52 : EndIf ;*1.02564
  If GetGadgetState(#itu)=0 : itu.f=1 : EndIf
  
  dar.f = ((twidth.l-acleft.l-acright.l)/twidth.l)/((theight.l-actop.l-acbottom.l)/theight.l)*aspectinfo.f*itu.f
  
  If GetGadgetState(#anamorphic)=1
    dar_orig.f=(twidth.l-acleft.l-acright.l)/(theight.l-acbottom.l-actop.l)*itu.f
    SetGadgetText(#height,StrF(RoundByClosest(ValF(GetGadgetText(#width))/dar_orig.f,Val(GetGadgetText(#modheight))),0))
    SetGadgetText(#dar,StrF(dar.f,4))
  EndIf
  
  If GetGadgetState(#anamorphic)=0
    SetGadgetText(#dar,StrF(dar.f,4))
    SetGadgetText(#height,StrF(RoundByClosest(ValF(GetGadgetText(#width))/dar.f,Val(GetGadgetText(#modheight))),0))
  EndIf
  
  height.l=ValF(GetGadgetText(#height))
  width.l=ValF(GetGadgetText(#width))
  
  If GetGadgetState(#allowresize)=0
    SetGadgetText(#height,Str(theight.l))
    SetGadgetText(#width,Str(twidth.l))
  EndIf
  
  If Val(GetGadgetText(#topcrop))%2 = 0
    SetGadgetColor(#topcrop,#PB_Gadget_BackColor,$33CC00)
  Else
    SetGadgetColor(#topcrop,#PB_Gadget_BackColor,$0000FF)
  EndIf
  
  If Val(GetGadgetText(#bottomcrop))%2 = 0
    SetGadgetColor(#bottomcrop,#PB_Gadget_BackColor,$33CC00)
  Else
    SetGadgetColor(#bottomcrop,#PB_Gadget_BackColor,$0000FF)
  EndIf
  
  If Val(GetGadgetText(#leftcrop))%2 = 0
    SetGadgetColor(#leftcrop,#PB_Gadget_BackColor,$33CC00)
  Else
    SetGadgetColor(#leftcrop,#PB_Gadget_BackColor,$0000FF)
  EndIf
  
  If Val(GetGadgetText(#rightcrop))%2 = 0
    SetGadgetColor(#rightcrop,#PB_Gadget_BackColor,$33CC00)
  Else
    SetGadgetColor(#rightcrop,#PB_Gadget_BackColor,$0000FF)
  EndIf
  
  SetGadgetText(#arerror,StrF((dar.f/(ValF(GetGadgetText(#width))/ValF(GetGadgetText(#height))))*100-100,4))
  
EndProcedure


Procedure silentresize()
  
  SetGadgetText(#width,Str(RoundByX(twidth.l/100*GetGadgetState(#trackwidth),16,#True)))
  silentscale()
  
EndProcedure

Procedure checkifo()
  
  ClearGadgetItems(#audiotrack)
  ClearGadgetItems(#subs)
  
  AddGadgetItem(#subs,-1,"none")
  AddGadgetItem(#audiotrack,-1,"none")
  
  If windows=#True : mplayer.s=Chr(34)+GetGadgetText(#pathtomplayer)+Chr(34) : EndIf
  
  If IsWindow(#Window_1)=0 : Open_Window_1() : EndIf
  HideWindow(#Window_1,0)
  SetActiveWindow(#Window_1)
  
  ClearGadgetItems(#pgc)
  
  DeleteFile(here.s+"mplayer.log")
  DeleteFile(here.s+"mplayer.bat")
  CreateFile(987,here.s+"mplayer.bat")
  WriteString(987,mplayer.s+" -vo null -identify -frames 1 "+Chr(34)+inputfile.s+Chr(34)+" > mplayer.log")
  CloseFile(987)
  If windows=#True
    RunProgram(here.s+"mplayer.bat","",here.s,#PB_Program_Wait)
  EndIf
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"mplayer.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"mplayer.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  
  fh=OpenFile(#PB_Any,here.s+"mplayer.log")
  While Eof(fh)=0
    mess.s=ReadString(fh)
    If FindString(mess.s,"ID_DVD_TITLE_",0) And FindString(mess.s,"LENGTH",0)
      AddGadgetItem(#pgc,-1,mess.s)
    EndIf
  Wend
  CloseFile(fh)
  
  SetGadgetState(#pgc,0)
  
  Repeat
    Delay(1)
    Event = WaitWindowEvent()
    Select Event
    Case #PB_Event_Gadget
      Select EventGadget()
        
      Case #pgcaccept
        pgc.s=GetGadgetText(#pgc)
        pgcid.l=Val(StringField(GetGadgetText(#pgc),4,"_"))
        HideWindow(#Window_1,1)
        Event = #PB_Event_CloseWindow
      EndSelect
    EndSelect
  Until Event = #PB_Event_CloseWindow
  
  
  DeleteFile(here.s+"mplayer.log")
  DeleteFile(here.s+"mplayer.bat")
  CreateFile(987,here.s+"mplayer.bat")
  WriteString(987,mplayer.s+" -identify -frames 1 dvd://"+Str(pgcid.l)+" "+Chr(34)+inputfile.s+Chr(34)+" > mplayer.log")
  CloseFile(987)
  If windows=#True
    RunProgram(here.s+"mplayer.bat","",here.s,#PB_Program_Wait)
  EndIf
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"mplayer.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"mplayer.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  fh=OpenFile(#PB_Any,here.s+"mplayer.log")
  While Eof(fh)=0
    mess.s=ReadString(fh)
    
    If FindString(mess,"ID_VIDEO_WIDTH",0)
      twidth.l=Val(StringField(mess.s,2,"="))
    EndIf
    If FindString(mess,"ID_VIDEO_HEIGHT",0)
      theight.l=Val(StringField(mess.s,2,"="))
    EndIf
    If FindString(mess,"LENGTH",0) And FindString(mess,"ID_DVD_TITLE",0) And FindString(mess,"_"+Str(pgcid.l)+"_",0)
      tsec.l=Val(Trim(StringField(mess.s,2,"=")))
    EndIf
    If FindString(mess,"ID_VIDEO_FPS",0)
      framerate.f=ValF(Trim(StringField(mess.s,2,"=")))
    EndIf
    If FindString(mess,"VDec: vo config request",0)
      ;VDec: vo config request - 720 x 480
      twidth.l=Val(Trim(Mid(mess.s,FindString(mess.s,"-",0)+1,FindString(mess.s,"x",0)-FindString(mess.s,"-",0)-2)))
      theight.l=Val(Trim(Mid(mess.s,FindString(mess.s,"x",0)+1,FindString(mess.s,"(",0)-FindString(mess.s,"x",0)-2)))
    EndIf
    If FindString(mess.s,"Movie-Aspect is",0)
      ar.s=StringField(mess.s,2,"=")
      ar.s=Trim(Mid(mess.s,FindString(mess.s," ",16),FindString(mess.s,":",0)-16))
    EndIf
    If FindString(mess.s,"ID_VIDEO_ASPECT",0)
      ar.s=StringField(mess.s,2,"=")
    EndIf
    If FindString(mess,"audio stream:",0) And FindString(mess.s,"language:",0)
      ;If FindString(mess,"ID_AUDIO_ID",0)
      If Right(mess.s,1)="." : mess.s=Left(mess.s,Len(mess.s)-1) : EndIf
      AddGadgetItem(#audiotrack,-1,mess.s)
    EndIf
    If FindString(mess,"subtitle ( sid )",0)
      AddGadgetItem(#subs,-1,mess.s)
    EndIf
    
    If FindString(mess.s,"ID_VIDEO_FORMAT",0)
      
      If FindString(mess,"MPEG",0)
        videocodec.s="mpeg2"
      EndIf
      If FindString(mess,"MPEG2",0)
        videocodec.s="mpeg2"
      EndIf
      If FindString(mess,"WVC1",0)
        videocodec.s="VC1"
      EndIf
      If FindString(mess,"XVID",0)
        videocodec.s="xvid"
      EndIf
      If FindString(mess,"DIVX",0)
        videocodec.s="divx"
      EndIf
      If FindString(mess,"AVC",0)
        videocodec.s="h264"
      EndIf
      
    EndIf
    
  Wend
  
  CloseFile(fh)
  
  
  framecount.l=tsec.l*framerate.f
  
  SetGadgetText(#arcombo,ar.s)
  
  If CountGadgetItems(#audiotrack)>1 : SetGadgetState(#audiotrack,1) : EndIf
  If CountGadgetItems(#audiotrack)<=1 : SetGadgetState(#audiotrack,0) : EndIf
  If tsec.l > 1 : SetGadgetText(#videolenght,StrF(tsec.l/60,3)) : EndIf
  
  If GetGadgetText(#arcombo)="" : SetGadgetText(#arcombo,StrF(twidth.l/theight.l,4)) : EndIf
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="d2v"
    fh = ReadFile(#PB_Any,GetGadgetText(#inputstring))
    While Eof(fh) = #False
      line.s = ReadString(fh)
      If FindString(line.s,"Aspect_Ratio=",1)
        start=FindString(line.s,"Aspect_Ratio=",1)
        len=Len(line.s)
        ar.s=Mid(line.s,start+13,len-start)
      EndIf
      If FindString(line.s,"Picture_Size=",1)
        twidth.l=Val(Mid(StringField(line.s,1,"x"),14,4))
        theight.l=Val(StringField(line.s,2,"x"))
      EndIf
    Wend
    If ar.s="16:9" :  SetGadgetText(#arcombo,"1.7778") : EndIf
    If ar.s="4:3" :  SetGadgetText(#arcombo,"1.3334") : EndIf
    If ar.s="1:1" :  SetGadgetText(#arcombo,"1") : EndIf
    
  EndIf
  
  messinfo.s="Input File: "+GetFilePart(inputfile.s)+Chr(10)
  messinfo.s=messinfo.s+"Video Codec :"+videocodec.s+Chr(10)
  messinfo.s=messinfo.s+"Width: "+Str(twidth.l)+Chr(10)
  messinfo.s=messinfo.s+"Height: "+Str(theight.l)+Chr(10)
  messinfo.s=messinfo.s+"Framerate: "+StrF(framerate.f,3)+Chr(10)
  messinfo.s=messinfo.s+"Framecount: "+Str(framecount.l)+Chr(10)
  messinfo.s=messinfo.s+"Aspect Ratio: "+ar.s+Chr(10)
  messinfo.s=messinfo.s+"Duration(sec): "+Str(tsec.l)+Chr(10)
  messinfo.s=messinfo.s+Trim(mess2.s)
  
  SetGadgetText(#basicfile,messinfo.s)
  
  Debug("twidth.l="+Str(twidth.l))
  Debug("theight.l="+Str(theight.l))
  Debug("framerate.f="+StrF(framerate.f))
  Debug("framecount.l="+Str(tsec.l*framerate.f))
  Debug("tsec.l="+Str(tsec.l))
  Debug("ar.s"=ar.s)
  If tsec.l<5 : tsec.l=framecount.l/framerate.f : EndIf
  
  SetGadgetText(#widthf,Str(twidth.l))
  SetGadgetText(#heightf,Str(theight.l))
  SetGadgetText(#framecountf,Str(framecount.l))
  SetGadgetText(#frameratef,StrF(framerate.f,3))
  
  dimb()
  
  autocrop()
  
EndProcedure


Procedure checkmediahandbrake()
  
  
  SetGadgetText(#encodewith,"Use HandBrakeCLI for Encoding")
  handbrakeoff()
  
  ClearGadgetItems(#audiotrack)
  ClearGadgetItems(#subs)
  
  AddGadgetItem(#subs,-1,"none")
  AddGadgetItem(#audiotrack,-1,"none")
  
  
  SetGadgetText(#bottomcrop,"")
  SetGadgetText(#topcrop,"")
  SetGadgetText(#leftcrop,"")
  SetGadgetText(#rightcrop,"")
  
  twidth.l=0
  theight.l=0
  tsec.l=0
  ar.s=""
  
  CreateFile(987,here.s+"hbanalysis.bat")
  WriteString(987,Chr(34)+handbrakecli.s+Chr(34)+" -t 0 -i "+Chr(34)+inputfile.s+Chr(34)+" 2> mplayer.log")
  CloseFile(987)
  
  If windows=#True
    RunProgram(here.s+"hbanalysis.bat","",here.s,#PB_Program_Wait)
  EndIf
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"hbanalysis.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"hbanalysis.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  
  fh=OpenFile(#PB_Any,here.s+"mplayer.log")
  While Eof(fh)=0
    mess.s=ReadString(fh)
    
    If FindString(mess,"+ size",0)
      line.s=StringField(mess.s,2,"size")
      temp.s=StringField(line.s,2,":")
      twidth.l=Val(StringField(Trim(temp.s),1,"x"))
      theight.l=Val(StringField(Trim(temp.s),2,"x"))
      line.s=StringField(mess.s,2,"display aspect:")
      ar.s=StringField(Trim(StringField(line.s,2,":")),1,",")
      
      If FindString(mess.s,"25.",0) : framerate.f=25.000 : EndIf
      If FindString(mess.s,"23.9",0) : framerate.f=23.976 : EndIf
      If FindString(mess.s,"29.9",0) : framerate.f=29.97 : EndIf
      If FindString(mess.s,"30.0",0) : framerate.f=30 : EndIf
      
    EndIf
    
    If FindString(mess,"duration",0)
      line.s=StringField(mess.s,2,"duration")
      hour.l=Val(StringField(StringField(line.s,1,":"),2," "))
      minute.l=Val(StringField(StringField(line.s,2,":"),1,":"))
      second.l=Val(StringField(line.s,3,":"))
    EndIf
    
    If FindString(mess,"+ autocrop",0)
      line.s=StringField(mess.s,2,":")
      actop.l=Val(StringField(line.s,1,"/"))
      acbottom.l=Val(StringField(line.s,2,"/"))
      acleft.l=Val(StringField(line.s,3,"/"))
      acright.l=Val(StringField(line.s,4,"/"))
    EndIf
    
    If FindString(mess,"+",0) And FindString(mess.s,",",0) And FindString(mess.s,"audio",0)=0
      
      If FindString(mess.s,"AC3",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      If FindString(mess.s,"DTS",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      If FindString(mess.s,"MP3",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      If FindString(mess.s,"MP2",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      If FindString(mess.s,"AAC",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      If FindString(mess.s,"VORBIS",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      If FindString(mess.s,"PCM",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      If FindString(mess.s,"FLAC",0) : AddGadgetItem(#audiotrack,-1,Trim(StringField(mess.s,2,","))) : EndIf
      
    EndIf
    
    If FindString(mess,"subtitles",0) And GetExtensionPart(inputfile.s)="mkv" And FindString(mess,"S_TEXT",0)
      mess.s=ReplaceString(mess.s,"[mkv]","")
      mess.s=ReplaceString(mess.s,"subtitles","")
      mess.s=ReplaceString(mess.s,"(","")
      mess.s=ReplaceString(mess.s,"),","")
      mess.s=ReplaceString(mess.s,")","")
      mess.s=ReplaceString(mess.s,"S_TEXT","")
      mess.s=ReplaceString(mess.s,"/UTF8","")
      mess.s=ReplaceString(mess.s,"/SSA","")
      mess.s=ReplaceString(mess.s,"S_VOBSUB","")
      mess.s=ReplaceString(mess.s,"Track ID ","")
      mess.s=StringField(mess.s,2,":")
      AddGadgetItem(#subs,-1,Trim(mess.s))
    EndIf
    
    If FindString(mess,"MPEG2",0)
      videocodec.s="mpeg2"
    EndIf
    If FindString(mess,"MPEG DVD",0)
      videocodec.s="mpeg2"
    EndIf
    If FindString(mess,"VC1",0)
      videocodec.s="vc1"
    EndIf
    If FindString(mess,"theora",0)
      videocodec.s="theora"
    EndIf
    If FindString(mess,"avc1",0)
      videocodec.s="h.264"
    EndIf
    If FindString(mess,"mpeg4",0)
      videocodec.s="mpeg4 asp"
    EndIf
    If FindString(mess,"fraps",0)
      videocodec.s="fraps"
    EndIf
    If FindString(mess,"h.264",0)
      videocodec.s="h264"
    EndIf
    If FindString(mess,"lagarith",0)
      videocodec.s="lagarith"
    EndIf
    If FindString(mess,"mjpeg",0)
      videocodec.s="mjpeg"
    EndIf
    
    
    If FindString(mess,"ffvc1",0)
      videocodec.s="vc1"
    EndIf
    
  Wend
  
  CloseFile(fh)
  
  tsec.l=hour.l*60*60+minute.l*60+second.l
  
  framecount.l=tsec.l*framerate.f
  
  SetGadgetText(#arcombo,ar.s)
  
  
  
  If CountGadgetItems(#audiotrack)>1 : SetGadgetState(#audiotrack,1) : EndIf
  If CountGadgetItems(#audiotrack)<=1 : SetGadgetState(#audiotrack,0) : EndIf
  If tsec.l > 1 : SetGadgetText(#videolenght,StrF(tsec.l/60,3)) : EndIf
  
  If GetGadgetText(#arcombo)="" : SetGadgetText(#arcombo,StrF(twidth.l/theight.l,4)) : EndIf
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="d2v"
    fh = ReadFile(#PB_Any,GetGadgetText(#inputstring))
    While Eof(fh) = #False
      line.s = ReadString(fh)
      If FindString(line.s,"Aspect_Ratio=",1)
        start=FindString(line.s,"Aspect_Ratio=",1)
        len=Len(line.s)
        ar.s=Mid(line.s,start+13,len-start)
      EndIf
      If FindString(line.s,"Picture_Size=",1)
        twidth.l=Val(Mid(StringField(line.s,1,"x"),14,4))
        theight.l=Val(StringField(line.s,2,"x"))
      EndIf
    Wend
    If ar.s="16:9" :  SetGadgetText(#arcombo,"1.7778") : EndIf
    If ar.s="4:3" :  SetGadgetText(#arcombo,"1.3334") : EndIf
    If ar.s="1:1" :  SetGadgetText(#arcombo,"1") : EndIf
    
  EndIf
  
  
  SetGadgetText(#bottomcrop,"")
  SetGadgetText(#leftcrop,"")
  SetGadgetText(#rightcrop,"")
  SetGadgetText(#topcrop,"")
  
  If actop.l>145 Or acbottom.l>145 Or acleft.l>145 Or acright.l>145
    
    If actop.l=theight.l Or acright.l=twidth.l
      actop.l=0
      acright.l=0
    EndIf
    
    MessageRequester("AutoCrop", "Please, check autocrop value", #PB_MessageRequester_Ok )
  EndIf
  
  SetGadgetText(#bottomcrop,Str(acbottom.l))
  SetGadgetText(#leftcrop,Str(acleft.l))
  SetGadgetText(#rightcrop,Str(acright.l))
  SetGadgetText(#topcrop,Str(actop.l))
  
  messinfo.s="Input File: "+GetFilePart(inputfile.s)+Chr(10)
  messinfo.s=messinfo.s+"Video Codec: "+videocodec.s+Chr(10)
  messinfo.s=messinfo.s+"Width: "+Str(twidth.l)+"; "
  messinfo.s=messinfo.s+"Heigh: "+Str(theight.l)+Chr(10)
  messinfo.s=messinfo.s+"Framerate: "+StrF(framerate.f,3)+"; "
  messinfo.s=messinfo.s+"Framecount: "+Str(framecount.l)+"; "
  messinfo.s=messinfo.s+"Duration(sec): "+Str(tsec.l)+Chr(10)
  messinfo.s=messinfo.s+"Aspect Ratio: "+ar.s+Chr(10)
  
  messinfo.s=messinfo.s+Trim(mess2.s)
  
  SetGadgetText(#basicfile,messinfo.s)
  
  Debug("twidth.l="+Str(twidth.l))
  Debug("theight.l="+Str(theight.l))
  Debug("framerate.f="+StrF(framerate.f))
  Debug("framecount.l="+Str(tsec.l*framerate.f))
  Debug("tsec.l="+Str(tsec.l))
  Debug("ar.s"=ar.s)
  If tsec.l<5 : tsec.l=framecount.l/framerate.f : EndIf
  
  SetGadgetText(#widthf,Str(twidth.l))
  SetGadgetText(#heightf,Str(theight.l))
  SetGadgetText(#framecountf,Str(framecount.l))
  SetGadgetText(#frameratef,StrF(framerate.f,3))
  
  If framerate.f=59.940 Or framerate.f=29.97
    result=MessageRequester("AutoMen","Possible Telecine pattern found."+Chr(13)+Chr(13)+"Allow IVTC ? FILM NTSC (29.97->23.976)",#PB_MessageRequester_YesNo)
    If result=#PB_MessageRequester_Yes : SetGadgetText(#mdeint,"FILM NTSC (29.97->23.976)") : EndIf
  EndIf
  
  SetGadgetState(#subs,0)
  
  dimb()
  
EndProcedure


Procedure checkmedia()
  
  If FindString(inputfile.s,"_1",0)
    For aa=1 To 128
      If FileSize(GetPathPart(inputfile)+Mid(GetFilePart(inputfile),0,Len(GetFilePart(inputfile))-3-Len(GetExtensionPart(inputfile)))+"_"+Str(aa)+"."+GetExtensionPart(inputfile))<>-1
        ;MessageRequester("",GetPathPart(inputfile)+Mid(GetFilePart(inputfile),0,Len(GetFilePart(inputfile))-3-Len(GetExtensionPart(inputfile)))+"_"+Str(aa)+"."+GetExtensionPart(inputfile))
        inputfile1.s=inputfile1.s+" "+Chr(34)+GetPathPart(inputfile)+Mid(GetFilePart(inputfile),0,Len(GetFilePart(inputfile))-3-Len(GetExtensionPart(inputfile)))+"_"+Str(aa)+"."+GetExtensionPart(inputfile)+Chr(34)
      EndIf
    Next aa
    If FileSize(GetPathPart(inputfile)+Mid(GetFilePart(inputfile),0,Len(GetFilePart(inputfile))-3-Len(GetExtensionPart(inputfile)))+"_2."+GetExtensionPart(inputfile))<>-1
      inputfile2.s=Mid(inputfile1.s,3,Len(inputfile1.s)-3)
      inputfile2.s=ReplaceString(inputfile2.s,".vob",".vob"+Chr(13),#PB_String_NoCase)
      MessageRequester("AutoMen","Found other connected files."+Chr(13)+Chr(13)+"Input file will be:"+Chr(13)+Chr(13)+Trim(ReplaceString(inputfile2.s,Chr(34),"")))
    EndIf
  EndIf
  
  
  ClearGadgetItems(#audiotrack)
  ClearGadgetItems(#subs)
  
  AddGadgetItem(#subs,-1,"none")
  AddGadgetItem(#audiotrack,-1,"none")
  
  SetGadgetText(#bottomcrop,"")
  SetGadgetText(#topcrop,"")
  SetGadgetText(#leftcrop,"")
  SetGadgetText(#rightcrop,"")
  
  twidth.l=0
  theight.l=0
  tsec.l=0
  ar.s=""
  videocodec.s=""
  analyzewith.s=""
  checkfile.s=inputfile.s
  
  If GetGadgetText(#encodewith)="Use AviSynth (only for X264)"
    
    MessageRequester("",here.s)
    
    CreateFile(987,here.s+"automen.avs")
    
    Select LCase(GetExtensionPart(inputfile.s))
      
    Case "vob","avi","mpeg","m2v","mpg","ogm","vro","mkv"
      WriteStringN(987,"Try {")
      WriteStringN(987,"FFVideoSource("+Chr(34)+inputfile.s+Chr(34)+", track = -1, cache = false, seekmode = 0)")
      WriteStringN(987,"}")
      WriteStringN(987,"Catch(Err_Msg) {")
      WriteStringN(987,"DirectShowSource("+Chr(34)+inputfile.s+Chr(34)+",audio=false)")
      WriteStringN(987,"}")
    Case "evo","ts","grf","m2t","mov","mp4","m2ts"
      WriteStringN(987,"Try {")
      WriteStringN(987,"DirectShowSource("+Chr(34)+inputfile.s+Chr(34)+",audio=false)")
      WriteStringN(987,"}")
      WriteStringN(987,"Catch(Err_Msg) {")
      WriteStringN(987,"FFVideoSource("+Chr(34)+inputfile.s+Chr(34)+", track = -1, cache = false, seekmode = 0)")
      WriteStringN(987,"}")
    Case "avs"
      WriteStringN(987,"Import("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "d2v"
      WriteStringN(987,"Mpeg2Source("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "dgm","dgv"
      WriteStringN(987,"DGSource("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "dga"
      WriteStringN(987,"AVCSource("+Chr(34)+inputfile.s+Chr(34)+")")
    Case "dgi"
      WriteStringN(987,"DGSource("+Chr(34)+inputfile.s+Chr(34)+")")
    Default
      WriteStringN(987,"Try {")
      WriteStringN(987,"DirectShowSource("+Chr(34)+inputfile.s+Chr(34)+",audio=false)")
      WriteStringN(987,"}")
      WriteStringN(987,"Catch(Err_Msg) {")
      WriteStringN(987,"FFVideoSource("+Chr(34)+inputfile.s+Chr(34)+", track = -1, cache = false, seekmode = 0)")
      WriteStringN(987,"}")
      
    EndSelect
    
    checkfile.s=here.s+"automen.avs"
    
    CloseFile(987)
    
    
  EndIf
  
  DeleteFile(here.s+"mplayer.log")
  DeleteFile(here.s+"mplayer.bat")
  DeleteFile(here.s+"automen.log")
  
  CreateFile(987,here.s+"mplayer.bat")
  
  If linux=#True
    WriteString(987,mplayer.s+" -speed 100 -vo null -vf cropdetect=24:2 -nosound -frames 500 -identify "+Chr(34)+checkfile.s+Chr(34)+" > mplayer.log")
  EndIf
  
  If windows=#True
    WriteString(987,mplayer.s+" -speed 100 -vo null -vf cropdetect=24:2 -nosound -frames 500 -identify "+Chr(34)+checkfile.s+Chr(34)+" 1>mplayer.log 2>automen.log")
  EndIf
  
  CloseFile(987)
  
  If windows=#True
    RunProgram(here.s+"mplayer.bat","",here.s,#PB_Program_Wait)
  EndIf
  
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"mplayer.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"mplayer.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  
  fh=OpenFile(#PB_Any,here.s+"mplayer.log")
  While Eof(fh)=0
    mess.s=ReadString(fh)
    
    If FindString(mess,"ID_VIDEO_WIDTH",0)
      twidth.l=Val(StringField(mess.s,2,"="))
    EndIf
    If FindString(mess,"ID_VIDEO_HEIGHT",0)
      theight.l=Val(StringField(mess.s,2,"="))
    EndIf
    If FindString(mess,"ID_START_TIME",0) And Val(Trim(StringField(mess.s,2,"=")))>0
      tsec.l=Val(Trim(StringField(mess.s,2,"=")))
    EndIf
    If FindString(mess,"ID_LENGTH",0) And Val(Trim(StringField(mess.s,2,"=")))>0
      tsec.l=Val(Trim(StringField(mess.s,2,"=")))
    EndIf
    If FindString(mess,"ID_VIDEO_FPS",0)
      framerate.f=ValF(Trim(StringField(mess.s,2,"=")))
    EndIf
    If FindString(mess.s,"-vf crop=",0)
      vcrop.s=StringField(mess.s,2,"=")
      vcrop.s=StringField(vcrop.s,1,")")
      Debug("crop="+vcrop.s)
    EndIf
    
    If FindString(mess,"VDec: vo config request",0)
      ;VDec: vo config request - 720 x 480
      twidth.l=Val(Trim(Mid(mess.s,FindString(mess.s,"-",0)+1,FindString(mess.s,"x",0)-FindString(mess.s,"-",0)-2)))
      theight.l=Val(Trim(Mid(mess.s,FindString(mess.s,"x",0)+1,FindString(mess.s,"(",0)-FindString(mess.s,"x",0)-2)))
    EndIf
    If FindString(mess.s,"Movie-Aspect is",0)
      ar.s=StringField(mess.s,2,"=")
      ar.s=Trim(Mid(mess.s,FindString(mess.s," ",16),FindString(mess.s,":",0)-16))
    EndIf
    If FindString(mess.s,"ID_VIDEO_ASPECT",0)
      ar.s=StringField(mess.s,2,"=")
    EndIf
    
    If FindString(mess,"ID_AUDIO_ID",0) And GetExtensionPart(inputfile.s)<>"mkv"
      AddGadgetItem(#audiotrack,-1,mess.s)
    EndIf
    
    If GetExtensionPart(inputfile.s)="mkv"
      
      If FindString(mess.s,"audio (",0) And FindString(mess.s,"-aid",0)
        AddGadgetItem(#audiotrack,-1,mess.s)
      EndIf
      
    EndIf
    
    
    If FindString(mess,"subtitles",0) And GetExtensionPart(inputfile.s)="mkv" And FindString(mess,"S_TEXT",0)
      mess.s=ReplaceString(mess.s,"[mkv]","")
      mess.s=ReplaceString(mess.s,"subtitles","")
      mess.s=ReplaceString(mess.s,"(","")
      mess.s=ReplaceString(mess.s,"),","")
      mess.s=ReplaceString(mess.s,")","")
      mess.s=ReplaceString(mess.s,"S_TEXT","")
      mess.s=ReplaceString(mess.s,"/UTF8","")
      mess.s=ReplaceString(mess.s,"/SSA","")
      mess.s=ReplaceString(mess.s,"S_VOBSUB","")
      mess.s=ReplaceString(mess.s,"Track ID ","")
      mess.s=StringField(mess.s,2,":")
      AddGadgetItem(#subs,-1,Trim(mess.s))
    EndIf
    
    If FindString(mess.s,"ID_VIDEO_FORMAT",0) Or FindString(mess.s,"ID_VIDEO_CODEC",0)
      
      If FindString(mess,"MPEG",0)
        videocodec.s="mpeg2"
      EndIf
      If FindString(mess,"MPG2",0)
        videocodec.s="mpeg2"
      EndIf
      If FindString(mess,"WVC1",0)
        videocodec.s="vc1"
      EndIf
      If FindString(mess,"VC-1",0)
        videocodec.s="vc1"
      EndIf
      If FindString(mess,"XVID",0)
        videocodec.s="xvid"
      EndIf
      If FindString(LCase(mess.s),"divx",0)
        videocodec.s="divx"
      EndIf
      If FindString(mess,"AVC",0)
        videocodec.s="h264"
      EndIf
      If FindString(mess,"avc1",0)
        videocodec.s="h264"
      EndIf
      If FindString(mess,"h264",0)
        videocodec.s="h264"
      EndIf
      If FindString(mess,"lagarith",0)
        videocodec.s="lagarith"
      EndIf
      If FindString(mess,"mjpeg",0)
        videocodec.s="mjpeg"
      EndIf
      If FindString(mess,"ffvp6f",0)
        videocodec.s="FFmpeg VP6 Flash"
      EndIf
      
      If FindString(mess,"ffvc1",0)
        videocodec.s="vc1"
      EndIf
    EndIf
    
    If FindString(mess,"VIDEO:  MPEG2",0)
      videocodec.s="mpeg2"
    EndIf
    
  Wend
  
  CloseFile(fh)
  
  framecount.l=tsec.l*framerate.f
  
  SetGadgetText(#arcombo,ar.s)
  
  
  
  If CountGadgetItems(#audiotrack)>1 : SetGadgetState(#audiotrack,1) : EndIf
  If CountGadgetItems(#audiotrack)<=1 : SetGadgetState(#audiotrack,0) : EndIf
  If tsec.l > 1 : SetGadgetText(#videolenght,StrF(tsec.l/60,3)) : EndIf
  
  If GetGadgetText(#arcombo)="" : SetGadgetText(#arcombo,StrF(twidth.l/theight.l,4)) : EndIf
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="d2v"
    fh = ReadFile(#PB_Any,GetGadgetText(#inputstring))
    While Eof(fh) = #False
      line.s = ReadString(fh)
      If FindString(line.s,"Aspect_Ratio=",1)
        start=FindString(line.s,"Aspect_Ratio=",1)
        len=Len(line.s)
        ar.s=Mid(line.s,start+13,len-start)
      EndIf
      If FindString(line.s,"Picture_Size=",1)
        twidth.l=Val(Mid(StringField(line.s,1,"x"),14,4))
        theight.l=Val(StringField(line.s,2,"x"))
      EndIf
    Wend
    If ar.s="16:9" :  SetGadgetText(#arcombo,"1.7778") : EndIf
    If ar.s="4:3" :  SetGadgetText(#arcombo,"1.3334") : EndIf
    If ar.s="1:1" :  SetGadgetText(#arcombo,"1") : EndIf
    
  EndIf
  
  
  actop.l=theight.l-Val(StringField(vcrop.s,2,":"))-Val(StringField(vcrop.s,4,":"))
  acleft.l=Val(StringField(vcrop.s,3,":"))
  acright.l=twidth.l-acleft.l-Val(StringField(vcrop.s,1,":"))
  acbottom.l=theight.l-(Val(StringField(vcrop.s,2,":"))+actop.l)
  Debug(" -cropleft "+Str(acleft.l)+" -croptop "+Str(actop.l)+" -cropright "+Str(acright.l)+" -cropbottom "+Str(acbottom.l)+" " )
  
  SetGadgetText(#bottomcrop,"")
  SetGadgetText(#leftcrop,"")
  SetGadgetText(#rightcrop,"")
  SetGadgetText(#topcrop,"")
  
  If actop.l>theight.l/2 Or acbottom.l>theight.l/2 Or acleft.l>twidth.l/2 Or acright.l>twidth.l/2
    
    If actop.l=theight.l Or acright.l=twidth.l
      actop.l=0
      acright.l=0
    EndIf
    
    MessageRequester("AutoCrop", "Please, check autocrop value", #PB_MessageRequester_Ok )
  EndIf
  
  SetGadgetText(#bottomcrop,Str(acbottom.l))
  SetGadgetText(#leftcrop,Str(acleft.l))
  SetGadgetText(#rightcrop,Str(acright.l))
  SetGadgetText(#topcrop,Str(actop.l))
  
  If ar.s="" : ar.s=StrF(twidth.l/theight.l,4) : EndIf
  
  
  Debug("twidth.l="+Str(twidth.l))
  Debug("theight.l="+Str(theight.l))
  Debug("framerate.f="+StrF(framerate.f))
  Debug("framecount.l="+Str(tsec.l*framerate.f))
  Debug("tsec.l="+Str(tsec.l))
  Debug("ar.s"=ar.s)
  If tsec.l<5 : tsec.l=framecount.l/framerate.f : EndIf
  
  
  If framerate.f<15 Or twidth.l<50 Or theight.l<50
    If start.l=1
      MessageRequester("AutoMen","There is some problem analizing your file"+Chr(13)+Chr(13)+"Now AutoMen will retry with different demuxer")
      start.l=0
      checkmediahandbrake()
    EndIf
  EndIf
  
  If framecount.l<100 : framecount.l=9999 : SetGadgetText(#framecountf,Str(framecount.l)) : MessageRequester("AutoMen","Unable to detect numbers of frames (added 9999 as fake value). Please check the bitrate!") : EndIf
  
  If framecount.l>100 : SetGadgetText(#framecountf,Str(framecount.l)) : EndIf
  
  
  SetGadgetText(#widthf,Str(twidth.l))
  SetGadgetText(#heightf,Str(theight.l))
  SetGadgetText(#framecountf,Str(framecount.l))
  SetGadgetText(#frameratef,StrF(framerate.f,3))
  
  messinfo.s="Input File: "+GetFilePart(inputfile.s)+Chr(10)
  messinfo.s=messinfo.s+"Video Codec: "+videocodec.s+Chr(10)
  messinfo.s=messinfo.s+"Width: "+Str(twidth.l)+"; "
  messinfo.s=messinfo.s+"Heigh: "+Str(theight.l)+Chr(10)
  messinfo.s=messinfo.s+"Framerate: "+StrF(framerate.f,3)+" fps"+Chr(10)
  messinfo.s=messinfo.s+"Framecount: "+Str(framecount.l)+Chr(10)
  messinfo.s=messinfo.s+"Duration(sec): "+Str(tsec.l)+Chr(10)
  messinfo.s=messinfo.s+"Aspect Ratio: "+ar.s+Chr(10)
  
  messinfo.s=messinfo.s+Trim(mess2.s)
  
  SetGadgetText(#basicfile,messinfo.s)
  
  
  If framerate.f=59.940 Or framerate.f=29.97
    result=MessageRequester("AutoMen","Possible Telecine pattern found."+Chr(13)+Chr(13)+"Allow IVTC ? FILM NTSC (29.97->23.976)",#PB_MessageRequester_YesNo)
    If result=#PB_MessageRequester_Yes : SetGadgetText(#mdeint,"FILM NTSC (29.97->23.976)") : EndIf
  EndIf
  
  SetGadgetState(#subs,0)
  
  dimb()
  
  silentresize()
  
  
EndProcedure

Procedure openinputfile()
  
  extsubs.s=""
  
  If linux=#True
    inputfile.s=OpenFileRequester("Open File to Encode", last.s, "Supported Movie File|*VOB;*.EVO;*.M2TS;*.TS;*.MTS;*.MKV;*.OGM;*.MPG;*.MPEG;*.AVS;*.AVI;*.M2T;VIDEO_TS.IFO;*.VRO;*.MP4;*.MOV;*.OGV*.FLV:*.mov;*vob;*.evo;*.m2ts;*.ts;*.avi;*.mts;*.mkv;.ogm;*.mpg;*.mpeg;*.svi;*.m2t;*.vro;video_ts.ifo;*.mp4;*.ogv;*.flv|All files|*.*",0)
  Else
    inputfile.s=OpenFileRequester("Open File to Encode", last.s, "Supported Movie File|*VOB;*.EVO;*.M2TS;*.TS;*.MTS;*.MKV;*.OGM;*.MPG;*.MPEG;*.AVS;*.AVI;*.M2T;*.VRO;*.D2V;*.DGA;*.AVS;*.GRF;*.DGM;*.DGV;*.MOV;video_ts.IFO;*.OGV;*.MP4;*.FLV|All files|*.*",0)
  EndIf
  
  If inputfile.s<>""
    SetGadgetText(#inputstring,inputfile.s)
    framecount.l=0
    framerate.f=0
    StatusBarText(#statusbar, 0,"")
    
    If GetGadgetText(#outputstring)=""
      If GetGadgetText(#container)="MKV": SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mkv") : EndIf
      If GetGadgetText(#container)="AVI": SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".avi") : EndIf
      If GetGadgetText(#container)="H264": SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".h264") : EndIf
      If GetGadgetText(#container)="MP4" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mp4") : EndIf
      If GetGadgetText(#container)="OGV" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".ogv") : EndIf
      If GetGadgetText(#container)="WMV" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".WMV") : EndIf
      outputfile.s=GetGadgetText(#outputstring)
    EndIf
    
    start.l=1
    
    exts.s=LCase(GetExtensionPart(inputfile.s))
    If exts.s<>"ifo"
      If GetGadgetState(#analyzewithhandbrake)=1
        checkmediahandbrake()
      Else
        checkmedia()
      EndIf
    EndIf
    If exts.s="ifo"
      checkifo()
    EndIf
    
    SetGadgetState(#trackwidth,87)
    silentresize()
  EndIf
  
  
  
EndProcedure


Procedure checkextension()
  
  If GetGadgetText(#outputstring)=""
    If GetGadgetText(#container)="MKV": SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mkv") : EndIf
    If GetGadgetText(#container)="AVI": SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".avi") : EndIf
    If GetGadgetText(#container)="H264": SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".h264") : EndIf
    If GetGadgetText(#container)="MP4" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mp4") : EndIf
    If GetGadgetText(#container)="FLV" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".flv") : EndIf
    If GetGadgetText(#container)="WMV" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".wmv") : EndIf
    If GetGadgetText(#container)="OGV" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"automen_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".ogv") : EndIf
    outputfile.s=GetGadgetText(#outputstring)
  EndIf
  
  If GetGadgetText(#outputstring)<>""
    outputfile.s=GetGadgetText(#outputstring)
    If GetGadgetText(#container)="MKV": SetGadgetText(#outputstring,Mid(outputfile.s,0,Len(GetGadgetText(#outputstring))-1-Len(GetExtensionPart(GetGadgetText(#outputstring))))+".mkv") : EndIf
    If GetGadgetText(#container)="H264": SetGadgetText(#outputstring,Mid(outputfile.s,0,Len(GetGadgetText(#outputstring))-1-Len(GetExtensionPart(GetGadgetText(#outputstring))))+".h264") : EndIf
    If GetGadgetText(#container)="AVI": SetGadgetText(#outputstring,Mid(outputfile.s,0,Len(GetGadgetText(#outputstring))-1-Len(GetExtensionPart(GetGadgetText(#outputstring))))+".avi") : EndIf
    If GetGadgetText(#container)="MP4" : SetGadgetText(#outputstring,Mid(outputfile.s,0,Len(GetGadgetText(#outputstring))-1-Len(GetExtensionPart(GetGadgetText(#outputstring))))+".mp4") : EndIf
    If GetGadgetText(#container)="FLV" : SetGadgetText(#outputstring,Mid(outputfile.s,0,Len(GetGadgetText(#outputstring))-1-Len(GetExtensionPart(GetGadgetText(#outputstring))))+".flv") : EndIf
    If GetGadgetText(#container)="OGV" : SetGadgetText(#outputstring,Mid(outputfile.s,0,Len(GetGadgetText(#outputstring))-1-Len(GetExtensionPart(GetGadgetText(#outputstring))))+".ogv") : EndIf
    If GetGadgetText(#container)="WMV" : SetGadgetText(#outputstring,Mid(outputfile.s,0,Len(GetGadgetText(#outputstring))-1-Len(GetExtensionPart(GetGadgetText(#outputstring))))+".wmv") : EndIf
    outputfile.s=GetGadgetText(#outputstring)
  EndIf
  
  
EndProcedure

Procedure statusbarmess()
  
  If GetGadgetText(#container)="MP4" And GetGadgetText(#videocodec)="X264"
    If GetGadgetText(#encodewith)="Mencoder for Encoding"
      StatusBarText(#statusbar, 0, "You cannot use Mencoder to make an MP4+X264 file. Switching to HandBrake")
      SetGadgetText(#encodewith,"Use HandBrakeCLI for Encoding")
      handbrakeoff()
      SetGadgetText(#container,"MP4")
      SetGadgetText(#videocodec,"X264")
    EndIf
  EndIf
  
  If GetGadgetText(#container)="MP4"
    If GetGadgetText(#audiocodec)="AAC Audio"
      If GetGadgetText(#videocodec)="XviD"
        If GetGadgetText(#encodewith)="Mencoder for Encoding"
          StatusBarText(#statusbar, 0, "You cannot use Mencoder to make an MP4+XviD+AAC file. Switching audio to MP3")
          SetGadgetText(#container,"MP4")
          SetGadgetText(#audiocodec,"MP3 Audio")
          SetGadgetText(#videocodec,"XviD")
        EndIf
      EndIf
    EndIf
  EndIf
  
  
  If GetGadgetText(#container)="AVI"
    If GetGadgetText(#audiocodec)="AAC Audio"
      If GetGadgetText(#videocodec)="XviD"
        If GetGadgetText(#encodewith)="Mencoder for Encoding"
          StatusBarText(#statusbar, 0, "You cannot use Mencoder to make an AVI+XviD+AAC file. Switching audio to MP3")
          SetGadgetText(#audiocodec,"MP3 Audio")
        EndIf
      EndIf
    EndIf
  EndIf
  
EndProcedure


Open_Window_0()
here.s=GetCurrentDirectory()
SetGadgetState(#videocodec,0)
SetGadgetState(#speedquality,6)

CompilerIf #PB_Compiler_OS = #PB_OS_Linux : linux=#True : CompilerEndIf
CompilerIf #PB_Compiler_OS = #PB_OS_Windows : windows=#True : CompilerEndIf

If FileSize(here.s+"menprofile.txt")=-1
  here.s=GetPathPart(ProgramFilename())
  If FileSize(here.s+"menprofile.txt")=-1
    MessageRequester("AutoMen","Unable to find menprofile.txt in AutoMen folder. Quitting...")
    End
  EndIf
EndIf


If FileSize(here.s+"automen.ini")=-1
  
  If linux=#True
    If FileSize("/usr/local/bin/mplayer")<>-1 : SetGadgetText(#pathtomplayer,"/usr/local/bin/mplayer") : EndIf
    If FileSize("/usr/bin/mplayer")<>-1 : SetGadgetText(#pathtomplayer,"/usr/bin/mplayer") : EndIf
    If FileSize("/usr/local/bin/mencoder")<>-1 : SetGadgetText(#pathtomencoder,"/usr/local/bin/mencoder") : EndIf
    If FileSize("/usr/bin/mencoder")<>-1 : SetGadgetText(#pathtomencoder,"/usr/bin/mencoder") : EndIf
    If FileSize("/usr/local/bin/mkvmerge")<>-1 : SetGadgetText(#pathtomkvmerge,"/usr/local/bin/mkvmerge") : EndIf
    If FileSize("/usr/bin/mkvmerge")<>-1 : SetGadgetText(#pathtomkvmerge,"/usr/bin/mkvmerge") : EndIf
    If FileSize("/usr/local/bin/MP4Box")<>-1 : SetGadgetText(#pathtomp4box,"/usr/local/bin/MP4Box") : EndIf
    If FileSize("/usr/bin/MP4Box")<>-1 : SetGadgetText(#pathtomp4box,"/usr/bin/MP4Box") : EndIf
    If FileSize("/usr/local/bin/HandBrakeCLI")<>-1 : SetGadgetText(#pathtohandbrakecli,"/usr/local/bin/HandBrakeCLI") : EndIf
    If FileSize("/usr/bin/HandBrakeCLI")<>-1 : SetGadgetText(#pathtohandbrakecli,"/usr/bin/HandBrakeCLI") : EndIf
    If FileSize("/usr/local/bin/ffmpeg")<>-1 : SetGadgetText(#pathtoffmpeg,"/usr/local/bin/ffmpeg") : EndIf
    If FileSize("/usr/bin/ffmpeg")<>-1 : SetGadgetText(#pathtoffmpeg,"/usr/bin/ffmpeg") : EndIf
  EndIf
  
  If windows=#True
    
    If FileSize(here.s+"applications\mplayer.exe")>1 : SetGadgetText(#pathtomplayer,here.s+"applications\mplayer.exe") : EndIf
    If FileSize(here.s+"applications\mencoder.exe")>1 : SetGadgetText(#pathtomencoder,here.s+"applications\mencoder.exe") : EndIf
    If FileSize(here.s+"applications\mkvmerge.exe")>1 : SetGadgetText(#pathtomkvmerge,here.s+"applications\mkvmerge.exe") : EndIf
    If FileSize(here.s+"applications\mp4box.exe")>1: SetGadgetText(#pathtomp4box,here.s+"applications\mp4box.exe") : EndIf
    If FileSize(here.s+"applications\handbrakecli.exe")>1 : SetGadgetText(#pathtohandbrakecli,here.s+"applications\handbrakecli.exe") : EndIf
    If FileSize(here.s+"applications\ffmpeg.exe")>1 : SetGadgetText(#pathtoffmpeg,here.s+"applications\ffmpeg.exe") : EndIf
    If FileSize(here.s+"applications\x264.exe")>1 : x264.s=Chr(34)+here.s+"applications\x264.exe"+Chr(34) : EndIf
    
    If FileSize(here.s+"applications\mplayer\mplayer.exe")>1 : SetGadgetText(#pathtomplayer,here.s+"applications\mplayer\mplayer.exe") : EndIf
    If FileSize(here.s+"applications\mplayer\mencoder.exe")>1 : SetGadgetText(#pathtomencoder,here.s+"applications\mplayer\mencoder.exe")  : EndIf
    If FileSize(here.s+"applications\mkvtoolnix\mkvmerge.exe")>1 : SetGadgetText(#pathtomkvmerge,here.s+"applications\mkvtoolnix\mkvmerge.exe")  : EndIf
    If FileSize(here.s+"applications\mp4box\mp4box.exe")>1 : SetGadgetText(#pathtomp4box,here.s+"applications\mp4box\\mp4box.exe")  : EndIf
    If FileSize(here.s+"applications\ffmpeg\ffmpeg.exe")>1 : SetGadgetText(#pathtoffmpeg,here.s+"applications\ffmpeg\ffmpeg.exe") : EndIf
    If FileSize(here.s+"applications\x264\x264.exe")>1 : x264.s=Chr(34)+here.s+"applications\x264\x264.exe"+Chr(34) : EndIf
    
    If FileSize(here.s+"mplayer.exe")>1 : SetGadgetText(#pathtomplayer,here.s+"mplayer.exe") : EndIf
    If FileSize(here.s+"mencoder.exe")>1 : SetGadgetText(#pathtomencoder,here.s+"mencoder.exe") : EndIf
    If FileSize(here.s+"mkvmerge.exe")>1 : SetGadgetText(#pathtomkvmerge,here.s+"mkvmerge.exe") : EndIf
    If FileSize(here.s+"mp4box.exe")>1 : SetGadgetText(#pathtomp4box,here.s+"mp4box.exe") : EndIf
    If FileSize(here.s+"handbrakecli.exe")>1 : SetGadgetText(#pathtohandbrakecli,here.s+"handbrakecli.exe") : EndIf
    If FileSize(here.s+"ffmpeg.exe")>1 : SetGadgetText(#pathtoffmpeg,here.s+"ffmpeg.exe") : EndIf
    If FileSize(here.s+"x264.exe")>1 : x264.s=Chr(34)+here.s+"x264.exe"+Chr(34) : EndIf
    
  EndIf
  
EndIf

loaddefault()

mplayer.s=Chr(34)+GetGadgetText(#pathtomplayer)+Chr(34)
mkvmerge.s=Chr(34)+GetGadgetText(#pathtomkvmerge)+Chr(34)
mencoder.s=Chr(34)+GetGadgetText(#pathtomencoder)+Chr(34)
mp4box.s=Chr(34)+GetGadgetText(#pathtomp4box)+Chr(34)
handbrakecli.s=Chr(34)+GetGadgetText(#pathtohandbrakecli)+Chr(34)
ffmpeg.s=Chr(34)+GetGadgetText(#pathtoffmpeg)+Chr(34)

If FileSize(GetGadgetText(#pathtomencoder))=-1 : MessageRequester("Mencoder", "No Mencoder found on path. Please browse for it and use Save Setting", #PB_MessageRequester_Ok) : EndIf
If FileSize(GetGadgetText(#pathtomplayer))=-1 : MessageRequester("Mplayer", "No Mplayer found on path. Please browse for it and use Save Setting", #PB_MessageRequester_Ok) : EndIf

If FileSize(GetGadgetText(#pathtomencoder))<>-1 : AddGadgetItem(#encodewith,-1,"Mencoder for Encoding") : EndIf
If FileSize(GetGadgetText(#pathtohandbrakecli))<>-1 :AddGadgetItem(#encodewith,-1,"Use HandBrakeCLI for Encoding") : EndIf
If FileSize(GetGadgetText(#pathtoffmpeg))<>-1 :AddGadgetItem(#encodewith,-1,"Use ffmpeg as encoder") : EndIf

If windows=#True
  If FileSize(ReplaceString(x264.s,Chr(34),""))<>-1
    AddGadgetItem(#encodewith,-1,"Use X264 As demuxer And encoder")
    AddGadgetItem(#encodewith,-1,"Use AviSynth (only for X264)")
  EndIf
EndIf

If linux=#True
  If FileSize("/usr/bin/x264")<>-1 Or FileSize("/usr/local/bin/x264")<>-1 : AddGadgetItem(#encodewith,-1,"Use X264 as demuxer and encoder") : EndIf
EndIf

SetGadgetState(#encodewith,0)

parseprofile()
handbrakeoff()

If OpenPreferences(here.s+"automen.ini")
  PreferenceGroup("AutoMEN")
  SetGadgetText(#encodewith,ReadPreferenceString("Select Encoder","Mencoder for Encoding"))
  SetGadgetText(#denoise,ReadPreferenceString("Select Denoise Level","Super Light"))
  SetGadgetText(#resizer,ReadPreferenceString("Select Resizer","2 bicubic"))
  SetGadgetText(#audiocodec,ReadPreferenceString("Select Audio Codec","MP3 Audio"))
  SetGadgetText(#videocodec,ReadPreferenceString("Select Video Codec","XviD"))
  SetGadgetText(#container,ReadPreferenceString("Select Container","AVI"))
  SetGadgetText(#pass,ReadPreferenceString("Select Pass","1 pass"))
  SetGadgetState(#speedquality,Val(ReadPreferenceString("Select Encoding Quality","6")))
  ClosePreferences()
EndIf

StatusBarText(#statusbar, 0, "If you like AutoMen, please consider a donation")

If GetGadgetState(#speedquality)=0 : SetGadgetState(#speedquality,6) : EndIf


Repeat ; Start of the event loop
  
  Event = WaitWindowEvent() ; This line waits until an event is received from Windows
  
  WindowID = EventWindow() ; The Window where the event is generated, can be used in the gadget procedures
  
  GadgetID = EventGadget() ; Is it a gadget event?
  
  EventType = EventType() ; The event type
  
  ;You can place code here, and use the result as parameters for the procedures
  
  If Event = #PB_Event_Gadget
    
    If GadgetID = #open
      SetGadgetText(#outputstring,"")
      openinputfile()
      
    ElseIf GadgetID = #save
      mess.s=GetCurrentDirectory()
      If inputfile.s<>"" : mess.s=GetPathPart(inputfile.s) : EndIf
      outputfile.s=SaveFileRequester("Save your file",mess.s,"*.*",0)
      If GetExtensionPart(outputfile.s)=""
        If GetGadgetText(#container)="MKV" : outputfile.s=outputfile.s+".mkv" : EndIf
        If GetGadgetText(#container)="MP4" : outputfile.s=outputfile.s+".mp4" : EndIf
        If GetGadgetText(#container)="H264" : outputfile.s=outputfile.s+".h264" : EndIf
        If GetGadgetText(#container)="AVI" : outputfile.s=outputfile.s+".avi" : EndIf
        If GetGadgetText(#container)="FLV" : outputfile.s=outputfile.s+".flv" : EndIf
        If GetGadgetText(#container)="OGV" : outputfile.s=outputfile.s+".ogv" : EndIf
        If GetGadgetText(#container)="WMV" : outputfile.s=outputfile.s+".wmv" : EndIf
      EndIf
      If outputfile.s : SetGadgetText(#outputstring,outputfile.s) : EndIf
      
    ElseIf GadgetID = #audiocodec
      If GetGadgetText(#audiocodec)="MP3 Audio"
        DisableGadget(#mp3mode,0)
      Else
        DisableGadget(#mp3mode,1)
      EndIf
      statusbarmess()
      
      
    ElseIf GadgetID = #savesetting
      savesetting()
      
    ElseIf GadgetID = #preview
      preview()
      
    ElseIf GadgetID = #play
      RunProgram(mplayer.s,Chr(34)+inputfile.s+Chr(34),here.s)
      
    ElseIf GadgetID = #cds
      Dimb()
      sanitycheck()
      
    ElseIf GadgetID = #makereport
      makereport()
      
      
    ElseIf GadgetID = #framecountf
      framecount.l=Val(GetGadgetText(#framecountf))
      Dimb()
      sanitycheck()
      
    ElseIf GadgetID = #frameratef
      framerate.f=ValF(GetGadgetText(#frameratef))
      Dimb()
      sanitycheck()
      
    ElseIf GadgetID = #widthf
      twidth.l=Val(GetGadgetText(#widthf))
      sanitycheck()
      
    ElseIf GadgetID = #heightf
      theight.l=Val(GetGadgetText(#heightf))
      sanitycheck()
      
      
    ElseIf GadgetID = #pass
      If FindString(GetGadgetText(#pass),"CRF",0) :  SetGadgetText(#Text_33,"Quant") :  DisableGadget(#cds,1) : SetGadgetText(#Text_32,"Quality") : EndIf
      If FindString(GetGadgetText(#pass),"CRF",0)=0 : SetGadgetText(#Text_33,"kbp/s") : DisableGadget(#cds,0) : SetGadgetText(#Text_32,"Video Bitrate") : EndIf
      
    ElseIf GadgetID = #videocodec
      checkextension()
      parseprofile()
      statusbarmess()
      If FindString(GetGadgetText(#pass),"CRF",0) :  SetGadgetText(#Text_33,"Quant") :  DisableGadget(#cds,1) : SetGadgetText(#Text_32,"Quality") : EndIf
      If FindString(GetGadgetText(#pass),"CRF",0)=0 : SetGadgetText(#Text_33,"kbp/s") : DisableGadget(#cds,0) : SetGadgetText(#Text_32,"Video Bitrate") : EndIf
      
      
    ElseIf GadgetID = #container
      checkextension()
      statusbarmess()
      
    ElseIf GadgetID = #buttonffmpeg
      file.s=OpenFileRequester("Automen - Select FFmpeg","","*.*",0)
      If file.s : SetGadgetText(#pathtoffmpeg,file.s) : ffmpeg.s=file.s : EndIf
      
    ElseIf GadgetID = #buttontomencoder
      file.s=OpenFileRequester("Automen - Select Mencoder","","*.*",0)
      If file.s : SetGadgetText(#pathtomencoder,file.s) : mencoder.s=file.s : EndIf
      
    ElseIf GadgetID = #buttonthandbrakecli
      file.s=OpenFileRequester("Automen - Select HandBrakeCLI","","*.*",0)
      If file.s : SetGadgetText(#pathtohandbrakecli,file.s) : handbrakecli.s=file.s : EndIf
      
    ElseIf GadgetID = #buttontomplayer
      file.s=OpenFileRequester("Automen - Select Mplayer","","*.*",0)
      If file.s : SetGadgetText(#pathtomplayer,file.s) : mplayer.s=file.s : EndIf
      
    ElseIf GadgetID = #buttontomp4box
      file.s=OpenFileRequester("Automen - Select MP4Box","","*.*",0)
      If file.s : SetGadgetText(#pathtomp4box,file.s) : mp4box.s=file.s : EndIf
      
    ElseIf GadgetID = #buttontomkvmerge
      file.s=OpenFileRequester("Automen - Select MKVMerge","","*.*",0)
      If file.s : SetGadgetText(#pathtomkvmerge,file.s) : mkvmerge.s=file.s : EndIf
      
      
    ElseIf GadgetID = #speedquality
      parseprofile()
      
      
    ElseIf GadgetID = #allowresize
      If GetGadgetState(#allowresize)=0
        SetGadgetText(#width,Str(twidth))
        SetGadgetText(#height,Str(theight))
        DisableGadget(#topcrop,1)
        DisableGadget(#rightcrop,1)
        DisableGadget(#bottomcrop,1)
        DisableGadget(#leftcrop,1)
        DisableGadget(#width,1)
        DisableGadget(#height,1)
      EndIf
      
      If GetGadgetState(#allowresize)=1
        DisableGadget(#topcrop,0)
        DisableGadget(#rightcrop,0)
        DisableGadget(#bottomcrop,0)
        DisableGadget(#leftcrop,0)
        DisableGadget(#width,0)
        DisableGadget(#height,0)
        silentscale()
      EndIf
      
    ElseIf GadgetID = #encodewith
      handbrakeoff()
      parseprofile()
      checkextension()
      statusbarmess()
      If FindString(GetGadgetText(#pass),"CRF",0) :  SetGadgetText(#Text_33,"Quant") :  DisableGadget(#cds,1) : SetGadgetText(#Text_32,"Quality") : EndIf
      If FindString(GetGadgetText(#pass),"CRF",0)=0 : SetGadgetText(#Text_33,"kbp/s") : DisableGadget(#cds,0) : SetGadgetText(#Text_32,"Video Bitrate") : EndIf
      
    ElseIf GadgetID = #audibit
      Dimb()
      
    ElseIf GadgetID =#analyzewithhandbrake
      If GetGadgetState(#analyzewithhandbrake)=1 And GetGadgetText(#inputstring)<>""
        checkmediahandbrake()
      EndIf
      
    ElseIf GadgetID = #removequeuejob
      RemoveGadgetItem(#queue,0)
      ;If CountGadgetItems(#queue)=0 : DeleteFile(here.s+"automen.bat") : EndIf
      
    ElseIf GadgetID = #trackwidth
      silentresize()
      
    ElseIf GadgetID = #height
      If ValF(GetGadgetText(#height))<>height : silentscale() : EndIf
      
    ElseIf GadgetID = #width
      If ValF(GetGadgetText(#width))<>width : silentscale() : EndIf
      
    ElseIf GadgetID = #topcrop
      If actop.l<>Val(GetGadgetText(#topcrop)): silentscale() : EndIf
      
    ElseIf GadgetID = #bottomcrop
      If acbottom.l<>Val(GetGadgetText(#bottomcrop)) : silentscale() : EndIf
      
    ElseIf GadgetID = #rightcrop
      If acright.l<>Val(GetGadgetText(#rightcrop)) : silentscale() : EndIf
      
    ElseIf GadgetID = #leftcrop
      If acleft.l<>Val(GetGadgetText(#leftcrop)) : silentscale() : EndIf
      
    ElseIf GadgetID = #modheight
      silentscale()
      
    ElseIf GadgetID = #modwidth
      silentscale()
      
    ElseIf GadgetID = #itu
      silentscale()
      
    ElseIf GadgetID = #anamorphic
      silentscale()
      
    ElseIf GadgetID = #arcombo
      silentscale()
      
    ElseIf GadgetID = #autocrop
      autocrop()
      
    ElseIf GadgetID = #encode
      If GetGadgetText(#encodewith)<>"Use HandBrakeCLI for Encoding"
        
        queuecount.l=0
        queue.l=0
        If GetGadgetText(#pass)="1 pass" : passx.l=2 : start() : EndIf
        If GetGadgetText(#pass)="2 pass"
          passx.l=3 : start()
          passx.l=4 : start()
        EndIf
        If GetGadgetText(#pass)="CRF 1 pass"
          passx.l=5
          start()
        EndIf
        If GetGadgetText(#pass)="Copy Video"
          passx.l=7
          start()
        EndIf
        If GetGadgetText(#pass)="Same Quality"
          passx.l=11
          start()
        EndIf
        
        If GetGadgetText(#pass)="1 pass + CRF Mode"
          passx.l=8 : start()
          passx.l=9 : start()
          passx.l=10 : start()
        EndIf
      EndIf
      If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding"
        queuecount.l=0
        queue.l=0
        passx.l=2
        start()
      EndIf
      
      
    ElseIf GadgetID = #addtoqueue
      If GetGadgetText(#encodewith)<>"Use HandBrakeCLI for Encoding"
        queuecount.l=queuecount.l+1
        queue.l=1
        If GetGadgetText(#pass)="1 pass" : passx.l=2 : start() : EndIf
        If GetGadgetText(#pass)="2 pass"
          passx.l=3 : start()
          passx.l=4 : start()
        EndIf
        If GetGadgetText(#pass)="CRF 1 pass"
          passx.l=5
          start()
        EndIf
        If GetGadgetText(#pass)="Copy Video"
          passx.l=7
          start()
        EndIf
        If GetGadgetText(#pass)="1 pass + CRF Mode"
          passx.l=8 : start()
          passx.l=9 : start()
          passx.l=10 : start()
        EndIf
      EndIf
      If GetGadgetText(#encodewith)="Use HandBrakeCLI for Encoding"
        queuecount.l=queuecount.l+1
        queue.l=1
        start()
      EndIf
      
    ElseIf GadgetID = #startqueue
      startqueue()
      
    ElseIf GadgetID = #extsub
      extsubs.s=OpenFileRequester("Select external subtitle file", last.s, "*.srt;*.sub;*.ssa|*.srt;*.sub;*.ssa|*.*|*.*",0)
      If extsubs.s<>""
        AddGadgetItem(#subs,-1,extsubs.s)
        SetGadgetText(#SUBs,extsubs)
      EndIf
      
      
    ElseIf GadgetID = #paypal
      MessageRequester("Thanks For Your Support!", "Without your donation AutoMen will be never a better application!", #PB_MessageRequester_Ok )
      RunProgram("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4278562","","")
      
    ElseIf GadgetID = #buttonaddtoqueue
      AddGadgetItem(#queue,-1,GetGadgetText(#addedtoqueue))
      
    EndIf
    
  EndIf
  
Until Event = #PB_Event_CloseWindow ; End of the event loop

End
;
; IDE Options = PureBasic 4.41 (Windows - x86)
; CursorPosition = 565
; FirstLine = 542
; Folding = -----
; EnableXP
; EnableUser
; UseIcon = ..\HDConvertTOXviD\icons\___logo.ico
; Executable = automen6_x86
; DisableDebugger
; EnableCompileCount = 1574
; EnableBuildCount = 174
; EnableExeConstant
; IDE Options = PureBasic 4.60 Beta 4 (Windows - x86)
; CursorPosition = 1516
; FirstLine = 1485
; Folding = -----
; EnableXP
; EnableUser
; UseIcon = ___logo.ico
; Executable = AutoMen_beta.exe
; DisableDebugger
; EnableCompileCount = 417
; EnableBuildCount = 1572
; EnableExeConstant