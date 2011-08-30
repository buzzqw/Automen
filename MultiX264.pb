; PureBasic Visual Designer v3.95 build 1485 (PB4Code)

IncludeFile "MultiX264_include.pb"

Global inputfile.s,framecount.l,framerate.f,ar.s,twidth.l,mess.s,theight.l,tsec.l,height.l,width.l,videocodec.s
Global acbottom.l,acleft.l,acright.l,actop.l,aspectinfo.f,mencoderbat.s,bitrate.s,workpath.s,itu.f,dar.f
Global messinfo.s,outputinfo.s,here.s,outputfile.s,pgcid.l
Global queue.l, queuecount.l,passx.l,mplayer.s,mkvmerge.s,mp4box.s,pgc.s,start.l,mux.s,vcrop.s
Global x264.s,mencoder.s,mkvmerge.s,mp4box.s,ffmpeg.s,encostring.s,filetoanalyze.s,eac3to.s,fileaudio.s,avs2yuv.s
Global faad.s,oggenc.s,aften.s,lame.s,flac.s,faac.s,neroaacenc.s,mkvinfo.s
Global linux,windows

Procedure clean()
  
  If GetGadgetState(#clean)=1
    AddGadgetItem(#queue,-1,"del /q "+Chr(34)+workpath.s+"multix264*.*"+Chr(34))
  EndIf
  
  If GetGadgetState(#shutdown)=1
    If linux=#True :  AddGadgetItem(#queue,-1,"shutdown -h now") : EndIf
    If windows=#True : AddGadgetItem(#queue,-1,"shutdown -s -t 30 -f") : EndIf
  EndIf
  
EndProcedure


Procedure muxmkv()
  
  If GetGadgetState(#anamorphic)=1
    
    If GetGadgetText(#arcombo)="1.7778"
      dar.f=itu.f*16/9*((Val(GetGadgetText(#width))/twidth.l)/(Val(GetGadgetText(#height))/theight.l))
    EndIf
    If GetGadgetText(#arcombo)="1.3334"
      dar.f=itu.f*4/3*((Val(GetGadgetText(#width))/twidth.l)/(Val(GetGadgetText(#height))/theight.l))
    EndIf
    If GetGadgetText(#arcombo)<>"1.7778"  And GetGadgetText(#arcombo)="1.3334"
      If Val(GetGadgetText(#height))=theight.l And twidth.l=Val(GetGadgetText(#width))
        dar.f=itu.f*1*acwidth.l/theight.l
      EndIf
      If Val(GetGadgetText(#height))<>theight.l And twidth.l<>Val(GetGadgetText(#width))
        dar.f=itu.f*1*((Val(GetGadgetText(#width))/twidth.l)/(Val(GetGadgetText(#height))/theight.l))
      EndIf
    EndIf
    
  EndIf
  
  If GetGadgetState(#anamorphic)=0
    dar.f=ValF(GetGadgetText(#width))/ValF(GetGadgetText(#height))
  EndIf
  
  fulldar.s=""
  
  If GetGadgetState(#anamorphic)=1
    fulldar.s=" --aspect-ratio -1:"+StrF(dar.f,6)
  EndIf
  
  If GetGadgetState(#anamorphic)=0 And GetGadgetState(#allowresize)=0
    fulldar.s=" --aspect-ratio -1:"+GetGadgetText(#arcombo)
  EndIf
  
  
  Select GetGadgetText(#mdeint)
  Case "FILM NTSC (29.97->23.976)","Telecine","Mixed Prog/Telecine"
    framerate.f=23.976
  Case "Change FPS to 23.976"
    framerate.f=23.976
  Case "Change FPS to 25"
    framerate.f=25
  Case "Change FPS to 29.97"
    framerate.f=29.97
  EndSelect
  
  mux.s=mkvmerge.s+" -o "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)+" --default-duration 0:"+StrF(framerate.f,3)+"fps "+fulldar.s+" "+Chr(34)+outputfile.s+Chr(34)
  
  If GetGadgetText(#audiotrack)<>"none"
    mux.s=mux.s+" "+Chr(34)+fileaudio.s+Chr(34)
  EndIf
  
  AddGadgetItem(#queue,-1,mux.s)
  
EndProcedure

Procedure muxmp4()
  
  ADD.s="-add "
  
  Select GetGadgetText(#mdeint)
  Case "FILM NTSC (29.97->23.976)","Telecine","Mixed Prog/Telecine"
    framerate.f=23.976
  Case "Change FPS to 23.976"
    framerate.f=23.976
  Case "Change FPS to 25"
    framerate.f=25
  Case "Change FPS to 29.97"
    framerate.f=29.97
  EndSelect
  
  mux.s=mp4box.s+" "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)+" -fps "+StrF(framerate.f,3)+" -add "+Chr(34)+outputfile.s+Chr(34)
  
  If GetGadgetText(#audiotrack)<>"none"
    mux.s=mux.s+" "+ADD.s+" "+Chr(34)+fileaudio.s+Chr(34)
  EndIf
  
  AddGadgetItem(#queue,-1,mux.s)
  
EndProcedure

Procedure muxh264()
  
  mux.s="copy "+Chr(34)+outputfile.s+Chr(34)+" "+Chr(34)+GetGadgetText(#outputstring)+Chr(34)
  
  AddGadgetItem(#queue,-1,mux.s)
  
  If GetGadgetText(#audiotrack)<>"none"
    ;mux.s="copy "+Chr(34)+fileaudio.s+Chr(34)+" "+Chr(34)+GetPathPart(GetGadgetText(#outputstring))+GetFilePart(fileaudio.s)+Chr(34)
    mux.s="copy "+Chr(34)+fileaudio.s+Chr(34)+" "+Chr(34)+Mid(GetGadgetText(#outputstring),0,Len(GetGadgetText(#outputstring))-4)+GetExtensionPart(fileaudio.s)+Chr(34)
    AddGadgetItem(#queue,-1,mux.s)
  EndIf
  
  
EndProcedure

Procedure mux()
  
  mux.s=""
  
  If GetExtensionPart(GetGadgetText(#outputstring))="mkv"
    muxmkv()
  EndIf
  
  If GetExtensionPart(GetGadgetText(#outputstring))="mp4"
    muxmp4()
  EndIf
  
  If GetExtensionPart(GetGadgetText(#outputstring))="h264"
    muxh264()
  EndIf
  
EndProcedure

Procedure audioffmpeg()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="ifo"
    dump.s=mplayer.s+" dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(GetGadgetText(#inputstring)),0,Len(GetPathPart(GetGadgetText(#inputstring)))-1)+Chr(34)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34)
    
    AddGadgetItem(#queue,0,dump.s)
    inputfile.s=workpath.s+"film.vob"
  EndIf
  
  fileaudio.s=""
  encostring.s=""
  
  If GetGadgetText(#audiocodec)="Copy Audio"
    
    encostring.s=ffmpeg.s+" -i "+Chr(34)+inputfile.s+Chr(34)+" -vn -acodec copy "
    
    mess.s=GetGadgetText(#audiotrack)
    aid.s=StringField(mess.s,2,"#")
    aid.s=StringField(aid.s,1,":")
    aid.s=StringField(aid.s,2,".")
    If FindString(aid.s,"[",0) : aid.s=StringField(aid.s,1,"[") : EndIf
    If FindString(aid.s,"(",0) : aid.s=StringField(aid.s,1,"(") : EndIf
    encostring.s=encostring.s+" -map ["+aid.s+":0] "
    
    If FindString(GetGadgetText(#audiotrack),"ac3",0) : filetoanalyze.s=workpath.s+"multix264_audio.ac3" : encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.ac3"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"dca",0) :filetoanalyze.s=workpath.s+"multix264_audio.dts" : encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.dts"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"dts-hd",0) :filetoanalyze.s=workpath.s+"multix264_audio.dts" : encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.dts"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"truehd",0) :filetoanalyze.s=workpath.s+"multix264_audio.dts" : encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.dts"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"flac",0) : filetoanalyze.s=workpath.s+"multix264_audio.flac" :encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.flac"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"mp2",0) : filetoanalyze.s=workpath.s+"multix264_audio.mp2" :encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.mp2"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"mp3",0) : filetoanalyze.s=workpath.s+"multix264_audio.mp3" :encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.mp3"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"aac",0) : filetoanalyze.s=workpath.s+"multix264_audio.aac" :encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.aac"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"pcm",0) : filetoanalyze.s=workpath.s+"multix264_audio.wav" :encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.wav"+Chr(34) : EndIf
    If FindString(GetGadgetText(#audiotrack),"vorbis",0) : filetoanalyze.s=workpath.s+"multix264_audio.ogg" :encostring.s=encostring.s+"-y "+Chr(34)+workpath.s+"multix264_audio.ogg"+Chr(34) : EndIf
    
  EndIf
  
  If GetExtensionPart(inputfile.s)="mkv"
    
    If windows=#True
      encostring.s=Chr(34)+GetPathPart(mkvmerge.s)+"mkvextract.exe"+Chr(34)+" tracks "+Chr(34)+inputfile.s+Chr(34)+" "
    EndIf
    
    If linux=#True
      If mkvmerge.s<>""
        encostring.s="mkvextract tracks "+Chr(34)+inputfile.s+Chr(34)+" "
      EndIf
    EndIf
    
    aid.s=StringField(GetGadgetText(#audiotrack),1,":")
    
    If FindString(GetGadgetText(#audiotrack),"A_",0)
      If FindString(GetGadgetText(#audiotrack),"AC3",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.ac3"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.ac3"+Chr(34)
      EndIf
      If FindString(GetGadgetText(#audiotrack),"DTS",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.dts"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.dts"+Chr(34)
      EndIf
      If FindString(GetGadgetText(#audiotrack),"FLAC",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.flac"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.flac"+Chr(34)
      EndIf
      If FindString(GetGadgetText(#audiotrack),"L2",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.mp2"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.mp2"+Chr(34)
      EndIf
      If FindString(GetGadgetText(#audiotrack),"L3",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.mp3"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.mp3"+Chr(34)
      EndIf
      If FindString(GetGadgetText(#audiotrack),"VORBIS",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.ogg"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.ogg"+Chr(34)
      EndIf
      If FindString(GetGadgetText(#audiotrack),"AAC",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.aac"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.aac"+Chr(34)
      EndIf
      If FindString(GetGadgetText(#audiotrack),"PCM",0)
        encostring.s=encostring.s+aid.s+":"+Chr(34)+workpath.s+"multix264_audio.wav"+Chr(34)
        filetoanalyze.s=Chr(34)+workpath.s+"multix264_audio.wav"+Chr(34)
      EndIf
    EndIf
    
  EndIf
  
  
  If GetGadgetText(#audiocodec)="Copy Audio"
    AddGadgetItem(#queue,-1,encostring.s)
    fileaudio.s=filetoanalyze.s
    encostring.s=""
  EndIf
  
  If GetGadgetText(#audiocodec)<>"Copy Audio"
    
    Select GetExtensionPart(inputfile.s)
    Case "mkv"
      AddGadgetItem(#queue,-1,encostring.s)
      encostring.s=ffmpeg.s+" -i "+filetoanalyze.s+" -vn "
    Default
      encostring.s=ffmpeg.s+" -i "+Chr(34)+inputfile.s+Chr(34)+" -vn "
      If GetGadgetState(#audiotrack)>1
        mess.s=GetGadgetText(#audiotrack)
        aid.s=StringField(mess.s,2,"#")
        aid.s=StringField(aid.s,1,":")
        aid.s=StringField(aid.s,2,".")
        If FindString(aid.s,"[",0) : aid.s=StringField(aid.s,1,"[") : EndIf
        If FindString(aid.s,"(",0) : aid.s=StringField(aid.s,1,"(") : EndIf
        encostring.s=encostring.s+" -map ["+aid.s+":0]"
      EndIf
    EndSelect
    
    If GetGadgetText(#channel)="2" : encostring.s=encostring.s+" -ac 2 " : EndIf
    If GetGadgetText(#channel)="1" : encostring.s=encostring.s+" -ac 1 " : EndIf
    If GetGadgetState(#audionormalize)=1 : encostring.s=encostring.s+" -vol 256 " : EndIf
    
    encostring.s=encostring.s+" -f wav -y "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)
    
    AddGadgetItem(#queue,-1,encostring.s)
    
    If GetGadgetText(#audiocodec)="MP3 Audio"
      fileaudio.s=workpath.s+"multix264_audio.mp3"
      encostring.s=lame.s+" -h "
      If GetGadgetText(#mp3mode)="cbr" : encostring.s=encostring.s+" --cbr -b "+GetGadgetText(#audibit)+"  "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)+" "+Chr(34)+workpath.s+"multix264_audio.mp3"+Chr(34) : EndIf
      If GetGadgetText(#mp3mode)="abr" : encostring.s=encostring.s+" --abr "+GetGadgetText(#audibit)+"  "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)+" "+Chr(34)+workpath.s+"multix264_audio.mp3"+Chr(34) : EndIf
    EndIf
    If GetGadgetText(#audiocodec)="AC3 Audio"
      fileaudio.s=workpath.s+"multix264_audio.ac3"
      encostring.s=aften.s+" "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)+" -b "+GetGadgetText(#audibit)+" "+Chr(34)+workpath.s+"multix264_audio.ac3"+Chr(34)
    EndIf
    If GetGadgetText(#audiocodec)="FLAC Audio"
      fileaudio.s=workpath.s+"multix264_audio.flac"
      encostring.s=flac.s+" "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)+" -o "+Chr(34)+workpath.s+"multix264_audio.flac"+Chr(34)
    EndIf
    If GetGadgetText(#audiocodec)="OGG Audio"
      fileaudio.s=workpath.s+"multix264_audio.ogg"
      encostring.s=oggenc.s+" -q "+GetGadgetText(#audibit)+" "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)+" -o "+Chr(34)+workpath.s+"multix264_audio.ogg"+Chr(34)
    EndIf
    If neroaacenc.s=""
      If GetGadgetText(#audiocodec)="AAC Audio"
        fileaudio.s=workpath.s+"multix264_audio.aac"
        encostring.s=faac.s+" -b "+GetGadgetText(#audibit)+" -o "+Chr(34)+workpath.s+"multix264_audio.aac"+Chr(34)+" "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)
      EndIf
    EndIf
    If neroaacenc.s<>""
      If GetGadgetText(#audiocodec)="AAC Audio"
        fileaudio.s=workpath.s+"multix264_audio.aac"
        encostring.s=neroaacenc.s+" -q "+GetGadgetText(#audibit)+" -ignorelength -if "+Chr(34)+workpath.s+"multix264.wav"+Chr(34)+" -of "+Chr(34)+workpath.s+"multix264_audio.aac"+Chr(34)
      EndIf
    EndIf
    
    
  EndIf
  
  AddGadgetItem(#queue,-1,encostring.s)
  
EndProcedure


Procedure eac3toaudio()
  
  Select LCase(GetExtensionPart(inputfile.s))
  Case "mkv","evo","vob","mpeg","mpg","ts","m2t","m2ts"
    
    If FindString(GetGadgetText(#audiotrack),"2.0",0)  : aacch.s="2" : EndIf
    If FindString(GetGadgetText(#audiotrack),"2.0",0) And GetGadgetText(#channel)="Original" : down.s=" -down2 " : EndIf
    If FindString(GetGadgetText(#audiotrack),"5.1",0) And GetGadgetText(#channel)="2" : down.s=" -down2 " : EndIf
    If FindString(GetGadgetText(#audiotrack),"7.1",0) And GetGadgetText(#channel)="2" : down.s=" -down2 " : EndIf
    If FindString(GetGadgetText(#audiotrack),"1.0 channels",0) :   down.s=" " : aacch.s="1" : EndIf
    If GetGadgetText(#sampling)<>"AUTO" : resampleaudio.s=" -resampleTo"+GetGadgetText(#sampling)+" " : EndIf
    If GetGadgetState(#audionormalize)=1 : normalize.s=" -normalize " : EndIf
    
    aid.s=Trim(StringField(GetGadgetText(#audiotrack),1,":"))
    
    If GetFilePart(inputfile.s)="film.vob"
      aid.s=Str(Val(Trim(StringField(StringField(GetGadgetText(#audiotrack),1,"f"),2,":")))+2)
      inputfile.s=workpath.s+"film.vob"
    EndIf
    
    If GetGadgetText(#audiocodec)="MP3 Audio"
      down.s=" -down16 -down2 "
      If FindString(GetGadgetText(#audiotrack),"1.0",0) :   down.s=" " : EndIf
      
      If GetGadgetText(#mp3mode)="abr"
        encostring.s=eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" "+aid.s+": stdout.wav "+down.s+resampleaudio.s+normalize.s+"| "+Chr(34)+here.s+"applications\lame\lame.exe"+Chr(34)+" - -h --abr "+GetGadgetText(#audibit)+" "+Chr(34)+workpath.s+"multix264_audio.mp3"+Chr(34)
      EndIf
      If GetGadgetText(#mp3mode)="cbr"
        encostring.s=eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" "+aid.s+": stdout.wav "+down.s+resampleaudio.s+normalize.s+"| "+Chr(34)+here.s+"applications\lame\lame.exe"+Chr(34)+" - -h --cbr -b "+GetGadgetText(#audibit)+" "+Chr(34)+workpath.s+"multix264_audio.mp3"+Chr(34)
      EndIf
      fileaudio.s=workpath.s+"multix264_audio.mp3"
    EndIf
    
    If GetGadgetText(#audiocodec)="OGG Audio"
      encostring.s=eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" "+aid.s+": stdout.wav "+resampleaudio.s+normalize.s+down.s+"| "+Chr(34)+here.s+"applications\oggenc\oggenc2.exe"+Chr(34)+" - -q "+GetGadgetText(#audibit)+" -o "+Chr(34)+workpath.s+"multix264_audio.ogg"+Chr(34)
      fileaudio.s=workpath.s+"multix264_audio.ogg"
    EndIf
    
    If GetGadgetText(#audiocodec)="AAC Audio"
      encostring.s=eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" "+aid.s+": stdout.wav "+resampleaudio.s+normalize.s+down.s+"| "+Chr(34)+here.s+"applications\neroaacenc\neroaacenc.exe"+Chr(34)+" -if - -q "+GetGadgetText(#audibit)+" -ignorelength -of "+Chr(34)+workpath.s+"multix264_audio.mp4"+Chr(34)
      fileaudio.s=workpath.s+"multix264_audio.mp4"
    EndIf
    
    If GetGadgetText(#audiocodec)="FLAC Audio"
      encostring.s=eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" "+aid.s+": "+Chr(34)+workpath.s+"multix264_audio.flac"+Chr(34)+resampleaudio.s+normalize.s+down.s
      fileaudio.s=workpath.s+"multix264_audio.flac"
    EndIf
    
    If GetGadgetText(#audiocodec)="AC3 Audio"
      encostring.s=eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" "+aid.s+": "+Chr(34)+workpath.s+"multix264_audio.ac3"+Chr(34)+resampleaudio.s+normalize.s+down.s
      fileaudio.s=workpath.s+"multix264_audio.ac3"
    EndIf
    
    If GetGadgetText(#audiocodec)="Copy Audio"
      extaudio.s=GetGadgetText(#audiotrack)
      If FindString(extaudio.s,"ac3",0) : extaudio.s="ac3" : EndIf
      If FindString(extaudio.s,"ac3 ex,",0 ): extaudio.s="ac3" : EndIf
      If FindString(extaudio.s,"dts master",0) : extaudio.s="dts" : EndIf
      If FindString(extaudio.s,"truehd/ac3,",0) : extaudio.s="dts" : EndIf
      If FindString(extaudio.s,"dts",0 ): extaudio.s="dts" : EndIf
      If FindString(extaudio.s,"dts",0 ): extaudio.s="dts" : EndIf
      If FindString(extaudio.s,"flac,",0) : extaudio.s="flac" : EndIf
      If FindString(extaudio.s,"mp2,",0) : extaudio.s="mp2" : EndIf
      If FindString(extaudio.s,"mp3,",0) : extaudio.s="mp3" : EndIf
      If FindString(extaudio.s,"aac,",0) : extaudio.s="aac" : EndIf
      If FindString(extaudio.s,"pcm,",0 ): extaudio.s="pcm" : EndIf
      If FindString(extaudio.s,"vorbis,",0) : extaudio.s="ogg" : EndIf
      
      encostring.s=eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" "+aid.s+": "+Chr(34)+workpath.s+"multix264_audio."+extaudio.s+Chr(34)
      fileaudio.s=workpath.s+"multix264_audio."+extaudio.s
    EndIf
    
    AddGadgetItem(#queue,-1,encostring.s)
    
  EndSelect
  
  
EndProcedure


Procedure audioencoding()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="ifo"
    dump.s=mplayer.s+" dvd://"+Str(pgcid.l)+" -dvd-device "+Chr(34)+Mid(GetPathPart(GetGadgetText(#inputstring)),0,Len(GetPathPart(GetGadgetText(#inputstring)))-1)+Chr(34)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34)
    
    AddGadgetItem(#queue,0,dump.s)
    inputfile.s=workpath.s+"film.vob"
  EndIf
  
  fileaudio.s=""
  encostring.s=""
  
  If GetGadgetText(#audiotrack)="none" Or GetGadgetText(#audiocodec)="No Audio"
    ProcedureReturn 0
  EndIf
  
  If linux=#True
    audioffmpeg()
  EndIf
  
  If windows=#True
    Select LCase(GetExtensionPart(inputfile.s))
    Case "mkv","evo","vob","mpeg","mpg","ts","m2t","m2ts"
      If eac3to.s<>""
        eac3toaudio()
      EndIf
      If eac3to.s=""
        audioffmpeg()
      EndIf
    Default
      audioffmpeg()
    EndSelect
  EndIf
  
EndProcedure


Procedure x264ffmpegpipe()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  outputfile.s=workpath.s+"multix264.h264"
  
  If LCase(GetExtensionPart(inputfile.s))="ifo"
    AddGadgetItem(#queue,0,mplayer.s+" dvd://"+Str(pgcid.l)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34))
  EndIf
  
  leftcrop.l=Val(GetGadgetText(#leftcrop))
  topcrop.l=Val(GetGadgetText(#topcrop))
  rightcrop.l=Val(GetGadgetText(#rightcrop))
  bottomcrop.l=Val(GetGadgetText(#bottomcrop))
  
  If GetGadgetState(#allowresize)=1
    width.l=Val(GetGadgetText(#width))
    height.l=Val(GetGadgetText(#height))
  EndIf
  
  encostring.s=ffmpeg.s+" -i "+Chr(34)+inputfile.s+Chr(34)+" "
  
  If GetGadgetState(#allowresize)=1
    
    If leftcrop.l+topcrop.l+rightcrop.l+bottomcrop.l>0
      encostring.s=encostring.s+"-vf crop="+Str(twidth.l-acleft.l-acright.l)+":"+Str(theight.l-actop.l-acbottom.l)+":"+Str(acright.l)+":"+Str(acbottom.l)
      If width.l+height.l>0
        encostring.s=encostring.s+",scale="+Str(width.l)+":"+Str(height.l)+" "
      EndIf
    EndIf
    
    If leftcrop.l+topcrop.l+rightcrop.l+bottomcrop.l=0
      If width.l+height.l>0
        encostring.s=encostring.s+"-s "+Str(width.l)+"x"+Str(height.l)+" "
      EndIf
    EndIf
    
  EndIf
  
  If GetGadgetState(#allowresize)=0
    width.l=twidth.l
    height.l=theight
  EndIf
  
  encostring.s=encostring.s+" -an -v 0 -pix_fmt yuv420p -f rawvideo - | "+x264.s+" "
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=1 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=2 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=8 : encostring.s=encostring.s+" --qp "+bitrate.s+" " : EndIf
  
  If GetGadgetText(#preset)<>"No Preset" : encostring.s=encostring.s+" --preset "+GetGadgetText(#preset)+" " : EndIf
  If GetGadgetText(#tuning)<>"none" : encostring.s=encostring.s+" --tune "+LCase(GetGadgetText(#tuning))+" " : EndIf
  If GetGadgetText(#x264mod)<>"" : encostring.s=encostring.s+" "+GetGadgetText(#x264mod)+" " : EndIf
  
  encostring.s=encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)+" - --input-res "+Str(width.l)+"x"+Str(height.l)
  
  If windows=#True : encostring.s=encostring.s+ " 2>MultiX264.log" : EndIf
  
  AddGadgetItem(#queue,-1,encostring.s)
  
  
EndProcedure


Procedure mkfifomencoder()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  outputfile.s=workpath.s+"multix264.h264"
  
  If LCase(GetExtensionPart(inputfile.s))="ifo"
    AddGadgetItem(#queue,0,mplayer.s+" dvd://"+Str(pgcid.l)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34))
  EndIf
  
  leftcrop.l=Val(GetGadgetText(#leftcrop))
  topcrop.l=Val(GetGadgetText(#topcrop))
  rightcrop.l=Val(GetGadgetText(#rightcrop))
  bottomcrop.l=Val(GetGadgetText(#bottomcrop))
  
  If GetGadgetState(#allowresize)=1
    width.l=Val(GetGadgetText(#width))
    height.l=Val(GetGadgetText(#height))
  EndIf
  
  If passx.l<>3
    AddGadgetItem(#queue,-1,"mkfifo "+Chr(34)+workpath.s+"multix264.fifo.yuv"+Chr(34))
  EndIf
  
  encostring.s=mencoder.s+" -nosound  -ovc raw -of rawvideo -ofps "+StrF(framerate.f,3)+" -o "+Chr(34)+workpath.s+"multix264.fifo.yuv"+Chr(34)+" "
  
  If GetGadgetState(#allowresize)=1
    If leftcrop.l+topcrop.l+rightcrop.l+bottomcrop.l>0
      encostring.s=encostring.s+" "+Chr(34)+inputfile.s+Chr(34)+" -vf crop="+Str(twidth.l-Val(GetGadgetText(#leftcrop))-Val(GetGadgetText(#rightcrop)))+":"+Str(theight.l-Val(GetGadgetText(#topcrop))-Val(GetGadgetText(#bottomcrop)))+":"+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)+","
      If GetGadgetText(#denoise)<>"NONE" :  encostring.s=encostring.s+"hqdn3d="+Str(GetGadgetState(#denoise)*2)+"," : EndIf
      encostring.s=encostring.s+"scale="+Str(width.l)+":"+Str(height.l)+",format=i420 2>&1 > /dev/null & "
    EndIf
    If leftcrop.l+topcrop.l+rightcrop.l+bottomcrop.l=0
      If GetGadgetText(#denoise)<>"NONE" :  encostring.s=encostring.s+" "+Chr(34)+inputfile.s+Chr(34)+" -vf scale="+Str(width.l)+":"+Str(height.l)+",hqdn3d="+Str(GetGadgetState(#denoise)*2)+",format=i420 2>&1 > /dev/null & " : EndIf
      If GetGadgetText(#denoise)="NONE": encostring.s=encostring.s+" "+Chr(34)+inputfile.s+Chr(34)+" -vf scale="+Str(width.l)+":"+Str(height.l)+",format=i420 2>&1 > /dev/null & " : EndIf
    EndIf
  EndIf
  
  If GetGadgetState(#allowresize)=0
    width.l=twidth.l
    height.l=theight
    If GetGadgetText(#denoise)<>"NONE" :  encostring.s=encostring.s+" "+Chr(34)+inputfile.s+Chr(34)+" -vf hqdn3d="+Str(GetGadgetState(#denoise)*2)+",format=i420 2>&1 > /dev/null & " : EndIf
    If GetGadgetText(#denoise)="NONE": encostring.s=encostring.s+" "+Chr(34)+inputfile.s+Chr(34)+" -vf format=i420 2>&1 > /dev/null & " : EndIf
  EndIf
  
  encostring.s=encostring.s+x264.s+"  "
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=1 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=2 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=8 : encostring.s=encostring.s+" --qp "+bitrate.s+" " : EndIf
  
  If GetGadgetText(#preset)<>"No Preset" : encostring.s=encostring.s+" --preset "+GetGadgetText(#preset)+" " : EndIf
  If GetGadgetText(#tuning)<>"none" : encostring.s=encostring.s+" --tune "+LCase(GetGadgetText(#tuning))+" " : EndIf
  If GetGadgetText(#x264mod)<>"" : encostring.s=encostring.s+" "+GetGadgetText(#x264mod)+" " : EndIf
  
  encostring.s=encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)+" "+Chr(34)+workpath.s+"multix264.fifo.yuv"+Chr(34)+" --input-res "+Str(width.l)+"x"+Str(height.l)
  
  AddGadgetItem(#queue,-1,encostring.s)
  
  If passx.l<>2
    AddGadgetItem(#queue,-1,"rm "+Chr(34)+workpath.s+"multix264.fifo.yuv"+Chr(34))
  EndIf
  
EndProcedure

Procedure x264mencoderpipe()
  
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  outputfile.s=workpath.s+"multix264.h264"
  
  If LCase(GetExtensionPart(inputfile.s))="ifo"
    AddGadgetItem(#queue,0,mplayer.s+" dvd://"+Str(pgcid.l)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34))
  EndIf
  
  leftcrop.l=Val(GetGadgetText(#leftcrop))
  topcrop.l=Val(GetGadgetText(#topcrop))
  rightcrop.l=Val(GetGadgetText(#rightcrop))
  bottomcrop.l=Val(GetGadgetText(#bottomcrop))
  
  If GetGadgetState(#allowresize)=1
    
    width.l=Val(GetGadgetText(#width))
    height.l=Val(GetGadgetText(#height))
    
    ;"C:\Program Files\PureBasic\AutoMen\applications\mencoder.exe" -demuxer lavf -mc 0 -vc mpeg12 -vf crop=720:432:0:72,
    ;  scale=640:272,hqdn3d=1 -o "C:\Program Files\PureBasic\AutoMen\automen_aaa.avi"
    ; -ovc xvid -xvidencopts bitrate=612:max_bframes=2:bquant_ratio=162:bquant_offset=100:
    ;vhq=2:me_quality=6:chroma_me:chroma_opt:hq_ac:trellis:lumi_mask:autoaspect:bvhq=1 -aid 0
    ; -oac mp3lame -lameopts cbr:br=128 -af volnorm=1 -channels 2 -lavdopts threads=2 -lavcopts
    ;threads=2 -passlogfile "C:\Program Files\PureBasic\AutoMen\automen_statsfile.log" "C:\Program Files\PureBasic\AutoMen\aaa.vob"
    
    ;mencoder.exe aaa.vob -really-quiet -ovc raw -vf format=i420 -nosound -o - | x264 --crf 24 -o aaa.mkv - 720x576
    
    encostring.s=mencoder.s+" "+Chr(34)+inputfile.s+Chr(34)+" -vf crop="+Str(twidth.l-Val(GetGadgetText(#leftcrop))-Val(GetGadgetText(#rightcrop)))+":"+Str(theight.l-Val(GetGadgetText(#topcrop))-Val(GetGadgetText(#bottomcrop)))+":"+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)+","
    
    encostring.s=encostring.s+"scale="+Str(width.l)+":"+Str(height.l)
    
    If GetGadgetText(#denoise)<>"NONE" :  encostring.s=encostring.s+",hqdn3d="+Str(GetGadgetState(#denoise)*2)+",format=i420 " : EndIf
    
  EndIf
  
  If GetGadgetState(#allowresize)=0
    width.l=twidth.l
    height.l=theight
    
    If GetGadgetText(#denoise)<>"NONE" :  encostring.s=mencoder.s+" "+Chr(34)+inputfile.s+Chr(34)+" -vf hqdn3d="+Str(GetGadgetState(#denoise)*2)+",format=i420 " : EndIf
    If GetGadgetText(#denoise)="NONE" :  encostring.s=mencoder.s+" "+Chr(34)+inputfile.s+Chr(34)+"  -vf format=i420 " : EndIf
  EndIf
  
  encostring.s=encostring.s+" -really-quiet -of rawvideo -ovc raw  -nosound -o - | "+x264.s+" "
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=1 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=2 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=8 : encostring.s=encostring.s+" --qp "+bitrate.s+" " : EndIf
  
  If GetGadgetText(#preset)<>"No Preset" : encostring.s=encostring.s+" --preset "+GetGadgetText(#preset)+" " : EndIf
  If GetGadgetText(#tuning)<>"none" : encostring.s=encostring.s+" --tune "+LCase(GetGadgetText(#tuning))+" " : EndIf
  If GetGadgetText(#x264mod)<>"" : encostring.s=encostring.s+" "+GetGadgetText(#x264mod)+" " : EndIf
  
  encostring.s=encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)+" - --input-res "+Str(width.l)+"x"+Str(height.l)
  
  If windows=#True : encostring.s=encostring.s+ " 2>MultiX264.log" : EndIf
  
  AddGadgetItem(#queue,-1,encostring.s)
  
  
EndProcedure

Procedure x264lavf()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  outputfile.s=workpath.s+"multix264.h264"
  
  If LCase(GetExtensionPart(inputfile.s))="ifo"
    AddGadgetItem(#queue,0,mplayer.s+" dvd://"+Str(pgcid.l)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34))
  EndIf
  
  encostring.s=x264.s+" "+Chr(34)+inputfile.s+Chr(34)+" "
  
  leftcrop.l=Val(GetGadgetText(#leftcrop))
  topcrop.l=Val(GetGadgetText(#topcrop))
  rightcrop.l=Val(GetGadgetText(#rightcrop))
  bottomcrop.l=Val(GetGadgetText(#bottomcrop))
  
  If GetGadgetState(#allowresize)=1
    width.l=Val(GetGadgetText(#width))
    height.l=Val(GetGadgetText(#height))
  EndIf
  
  If GetGadgetText(#encodewith)="lavf (need X264 with lavf support)" : encostring.s=encostring.s+"--demuxer lavf " : EndIf
  If GetGadgetText(#encodewith)="ffms (need X264 with ffms support)" : encostring.s=encostring.s+"--demuxer ffms " : EndIf
  If GetGadgetText(#encodewith)="avs (need X264 with avs support)" : encostring.s=encostring.s+"--demuxer avs " : EndIf
  If GetGadgetText(#encodewith)="auto (need X264 with auto support)" :encostring.s=encostring.s+"--demuxer auto " : EndIf
  
  ;  --vf, --video-filter <filter0>/<filter1>/... Apply video filtering to the input file
  ;    Available filters:
  ;    crop:left,top,right,bottom
  ;          removes pixels from the edges of the frame
  ;    resize:[width,height][,sar][,fittobox][,method]
  ;          resizes frames based on the given criteria:
  ;          - resolution only: resizes And adapts sar To avoid stretching
  ;          - sar only: sets the sar And resizes To avoid stretching
  ;          - resolution And sar: resizes To given resolution And sets the sar
  ;          - fittobox: resizes the video based on the desired contraints
  ;             - width, height, both
  ;          - fittobox And sar: same As above except With specified sar
  ;          using resizer method ["bicubic"]
  ;           - fastbilinear, bilinear, bicubic, experimental, point,
  ;           - area, bicublin, gauss, sinc, lanczos, spline
  ;    select_every:Step,offset1[,...]
  ;          apply a selection pattern To input frames
  ;          Step: the number of frames in the pattern
  ;          offsets: the offset into the Step To Select a frame
  ;          see: http://avisynth.org/mediawiki/Select#SelectEvery
  
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=1 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=2 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=8 : encostring.s=encostring.s+" --qp "+bitrate.s+" " : EndIf
  
  If GetGadgetText(#preset)<>"No Preset" : encostring.s=encostring.s+" --preset "+GetGadgetText(#preset)+" " : EndIf
  If GetGadgetText(#tuning)<>"none" : encostring.s=encostring.s+" --tune "+LCase(GetGadgetText(#tuning))+" " : EndIf
  If GetGadgetText(#x264mod)<>"" : encostring.s=encostring.s+" "+GetGadgetText(#x264mod)+" " : EndIf
  
  If GetGadgetState(#allowresize)=1
    encostring.s=encostring.s+"--video-filter crop:"+Str(leftcrop.l)+","+Str(topcrop.l)+","+Str(rightcrop.l)+","+Str(bottomcrop.l)+"/resize:"+Str(width.l)+","+Str(height.l)+",method="+GetGadgetText(#resizer)
  EndIf
  
  If GetGadgetText(#mdeint)="Progressive" : encostring.s=encostring.s+" --no-interlaced ": EndIf
  If GetGadgetText(#mdeint)="Interlaced" : encostring.s=encostring.s+" --no-interlaced ": EndIf
  
  
  encostring.s=encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)+" "
  
  If windows=#True : encostring.s=encostring.s+ "2>MultiX264.log" : EndIf
  
  AddGadgetItem(#queue,-1,encostring.s)
  
EndProcedure

Procedure x264dss()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  outputfile.s=workpath.s+"multix264.h264"
  
  leftcrop.l=Val(GetGadgetText(#leftcrop))
  topcrop.l=Val(GetGadgetText(#topcrop))
  rightcrop.l=Val(GetGadgetText(#rightcrop))
  bottomcrop.l=Val(GetGadgetText(#bottomcrop))
  
  encostring.s=x264.s+" "+Chr(34)+inputfile.s+Chr(34)+" "
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=1 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=2 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=8 : encostring.s=encostring.s+" --qp "+bitrate.s+" " : EndIf
  
  If GetGadgetText(#preset)<>"No Preset" : encostring.s=encostring.s+" --preset "+GetGadgetText(#preset)+" " : EndIf
  If GetGadgetText(#tuning)<>"none" : encostring.s=encostring.s+" --tune "+LCase(GetGadgetText(#tuning))+" " : EndIf
  If GetGadgetText(#x264mod)<>"" : encostring.s=encostring.s+" "+GetGadgetText(#x264mod)+" " : EndIf
  
  If GetGadgetState(#allowresize)=1
    encostring.s=encostring.s+"--video-filter crop:"+Str(leftcrop.l)+","+Str(topcrop.l)+","+Str(rightcrop.l)+","+Str(bottomcrop.l)+"/resize:"+Str(width.l)+","+Str(height.l)+",method="+GetGadgetText(#resizer)
  EndIf
  
  If GetGadgetText(#mdeint)="Progressive" : encostring.s=encostring.s+" --no-interlaced ": EndIf
  
  encostring.s=encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)+" "
  
  If windows=#True : encostring.s=encostring.s+ "2>MultiX264.log" : EndIf
  
  AddGadgetItem(#queue,-1,encostring.s)
  
  
EndProcedure


Procedure x264avs2yuvpipe()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  outputfile.s=workpath.s+"multix264.h264"
  
  If LCase(GetExtensionPart(inputfile.s))="ifo"
    AddGadgetItem(#queue,0,mplayer.s+" dvd://"+Str(pgcid.l)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34))
  EndIf
  
  CreateFile(987,workpath.s+"multix264.avs")
  
  If ExamineDirectory(0,here+"applications\filters\","*.dll")
    Repeat
      type=NextDirectoryEntry(0)
      If type=1 ; File
        a$=LCase(DirectoryEntryName(0))
        If FindString(a$,"soundout",0)=0
          If FindString(a$,"yadif",0)=0
            WriteStringN(987,"LoadPlugin("+Chr(34)+here+"applications\filters\"+a$+Chr(34)+")")
          EndIf
        EndIf
        If FindString(LCase(a$),"yadif",0)<>0
          WriteStringN(987,"LoadCPlugin("+Chr(34)+here+"applications\filters\"+a$+Chr(34)+")")
        EndIf
      EndIf
    Until type=0
  EndIf
  
  If ExamineDirectory(0,here+"applications\filters\","*.avsi")
    Repeat
      type=NextDirectoryEntry(0)
      If type=1 ; File
        a$=DirectoryEntryName(0)
        WriteStringN(987,"Import("+Chr(34)+here+"applications\filters\"+a$+Chr(34)+")")
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
      WriteStringN(987,"GaussResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+",p=75)")
    Case 7
      WriteStringN(987,"Spline36Resize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    Case 8
      WriteStringN(987,"Spline64Resize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    Case 9,10
      WriteStringN(987,"BlackmanResize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    Default
      WriteStringN(987,"LanczosResize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    EndSelect
    
  EndIf
  
  
  Select GetGadgetText(#denoise)
  Case "NONE"
  Case "Super Light"
    WriteStringN(987,"hqdn3d(2)")
  Case "Light"
    WriteStringN(987,"hqdn3d(3)")
  Case "Normal"
    WriteStringN(987,"hqdn3d(4)")
  Case "Severe"
    WriteStringN(987,"hqdn3d(6)")
  EndSelect
  
  CloseFile(987)
  
  encostring.s=avs2yuv.s+" "+Chr(34)+workpath.s+"multix264.avs"+Chr(34)+" - | "
  encostring.s=encostring.s+x264.s+" - --stdin y4m "
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=1 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=2 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=8 : encostring.s=encostring.s+" --qp "+bitrate.s+" " : EndIf
  
  If GetGadgetText(#preset)<>"No Preset" : encostring.s=encostring.s+" --preset "+GetGadgetText(#preset)+" " : EndIf
  If GetGadgetText(#tuning)<>"none" : encostring.s=encostring.s+" --tune "+LCase(GetGadgetText(#tuning))+" " : EndIf
  If GetGadgetText(#x264mod)<>"" : encostring.s=encostring.s+" "+GetGadgetText(#x264mod)+" " : EndIf
  
  encostring.s=encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)+" "
  
  If windows=#True : encostring.s=encostring.s+ " 2>MultiX264.log" : EndIf
  
  AddGadgetItem(#queue,-1,encostring.s)
  
  
EndProcedure


Procedure x264avs()
  
  workpath.s=GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))
  
  CreateDirectory(GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s))))
  
  If linux=#True  : workpath.s=workpath.s+"/" : EndIf
  If windows=#True : workpath.s=workpath.s+"\" : EndIf
  
  outputfile.s=workpath.s+"multix264.h264"
  
  If LCase(GetExtensionPart(inputfile.s))="ifo"
    AddGadgetItem(#queue,0,mplayer.s+" dvd://"+Str(pgcid.l)+" -dumpstream -dumpfile "+Chr(34)+workpath.s+"film.vob"+Chr(34))
  EndIf
  
  CreateFile(987,workpath.s+"multix264.avs")
  
  If ExamineDirectory(0,here+"applications\filters\","*.dll")
    Repeat
      type=NextDirectoryEntry(0)
      If type=1 ; File
        a$=LCase(DirectoryEntryName(0))
        If FindString(a$,"soundout",0)=0
          If FindString(a$,"yadif",0)=0
            WriteStringN(987,"LoadPlugin("+Chr(34)+here+"applications\filters\"+a$+Chr(34)+")")
          EndIf
        EndIf
        If FindString(LCase(a$),"yadif",0)<>0
          WriteStringN(987,"LoadCPlugin("+Chr(34)+here+"applications\filters\"+a$+Chr(34)+")")
        EndIf
      EndIf
    Until type=0
  EndIf
  
  If ExamineDirectory(0,here+"applications\filters\","*.avsi")
    Repeat
      type=NextDirectoryEntry(0)
      If type=1 ; File
        a$=DirectoryEntryName(0)
        WriteStringN(987,"Import("+Chr(34)+here+"applications\filters\"+a$+Chr(34)+")")
      EndIf
    Until type=0
  EndIf
  
  If GetGadgetText(#encodewith)="Force decoding with FFVideoSource"
    WriteStringN(987,"FFVideoSource("+Chr(34)+inputfile.s+Chr(34)+")")
  EndIf
  
  If GetGadgetText(#encodewith)="Force decoding with DirectShowSource"
    WriteStringN(987,"DirectShowSource("+Chr(34)+inputfile.s+Chr(34)+",audio=false)")
  EndIf
  
  If GetGadgetText(#encodewith)="Force decoding with DGSource"
    WriteStringN(987,"DGSource("+Chr(34)+inputfile.s+Chr(34)+")")
  EndIf
  
  If GetGadgetText(#encodewith)="Automatic Avisynth decoder"
    
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
    
    
  EndIf
  
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
      WriteStringN(987,"GaussResize("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+",p=75)")
    Case 7
      WriteStringN(987,"Spline36Resize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    Case 8
      WriteStringN(987,"Spline64Resize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    Case 9,10
      WriteStringN(987,"BlackmanResize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    Default
      WriteStringN(987,"LanczosResize ("+Str(width.l)+","+Str(height.l)+","+Str(leftcrop.l)+","+Str(topcrop.l)+",-"+Str(rightcrop.l)+",-"+Str(bottomcrop)+")")
    EndSelect
    
  EndIf
  
  
  Select GetGadgetText(#denoise)
  Case "NONE"
  Case "Super Light"
    WriteStringN(987,"hqdn3d(2)")
  Case "Light"
    WriteStringN(987,"hqdn3d(3)")
  Case "Normal"
    WriteStringN(987,"hqdn3d(4)")
  Case "Severe"
    WriteStringN(987,"hqdn3d(6)")
  EndSelect
  
  CloseFile(987)
  
  encostring.s=x264.s+" "+Chr(34)+workpath.s+"multix264.avs"+Chr(34)+" "
  
  bitrate.s=GetGadgetText(#videokbits)
  
  If passx.l=1 : encostring.s=encostring.s+" --bitrate "+bitrate.s+" " : EndIf
  If passx.l=2 : encostring.s=encostring.s+" --pass 1 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=3 : encostring.s=encostring.s+" --pass 2 --bitrate "+bitrate.s+" --stats "+Chr(34)+here.s+"multix264.stats"+Chr(34)+" " : EndIf
  If passx.l=4 : encostring.s=encostring.s+" --crf "+bitrate.s+" " : EndIf
  If passx.l=8 : encostring.s=encostring.s+" --qp "+bitrate.s+" " : EndIf
  
  If GetGadgetText(#preset)<>"No Preset" : encostring.s=encostring.s+" --preset "+GetGadgetText(#preset)+" " : EndIf
  If GetGadgetText(#tuning)<>"none" : encostring.s=encostring.s+" --tune "+LCase(GetGadgetText(#tuning))+" " : EndIf
  If GetGadgetText(#x264mod)<>"" : encostring.s=encostring.s+" "+GetGadgetText(#x264mod)+" " : EndIf
  
  encostring.s=encostring.s+" --output "+Chr(34)+outputfile.s+Chr(34)+" "
  
  If windows=#True : encostring.s=encostring.s+ "2>MultiX264.log" : EndIf
  
  AddGadgetItem(#queue,-1,encostring.s)
  
EndProcedure

Procedure handbrakeoff()
  
  StatusBarText(#statusbar, 0, "Resetting video and audio codec!")
  
  If GetGadgetText(#audiocodec)="MP3 Audio"
    
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
    
    ClearGadgetItems(#channel)
    AddGadgetItem(#channel,-1,"Original")
    AddGadgetItem(#channel,-1,"2")
    AddGadgetItem(#channel,-1,"1")
    
    SetGadgetText(#text50,"Audio Bitrate:")
    SetGadgetText(#text51,"kbit/s")
    SetGadgetState(#channel,1)
    DisableGadget(#mp3mode,0)
    DisableGadget(#audibit,0)
    GadgetToolTip(#audibit,"Bitrate of audio")
    
  EndIf
  
  If neroaacenc.s=""
    If GetGadgetText(#audiocodec)="AAC Audio"
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
      DisableGadget(#mp3mode,1)
      DisableGadget(#audibit,0)
      SetGadgetText(#text50,"Audio Bitrate:")
      SetGadgetText(#text51,"kbit/s")
      GadgetToolTip(#audibit,"Bitrate of audio")
    EndIf
  EndIf
  
  If neroaacenc.s<>""
    If GetGadgetText(#audiocodec)="AAC Audio"
      ClearGadgetItems(#audibit)
      AddGadgetItem(#audibit,-1,"1")
      AddGadgetItem(#audibit,-1,"0.9")
      AddGadgetItem(#audibit,-1,"0.8")
      AddGadgetItem(#audibit,-1,"0.7")
      AddGadgetItem(#audibit,-1,"0.6")
      AddGadgetItem(#audibit,-1,"0.5")
      AddGadgetItem(#audibit,-1,"0.4")
      AddGadgetItem(#audibit,-1,"0.3")
      AddGadgetItem(#audibit,-1,"0.2")
      AddGadgetItem(#audibit,-1,"0.1")
      SetGadgetState(#audibit,6)
      SetGadgetText(#text50,"Audio Quality")
      DisableGadget(#mp3mode,1)
      DisableGadget(#audibit,0)
      GadgetToolTip(#audibit,"Use higher values for better quality")
    EndIf
  EndIf
  
  
  If GetGadgetText(#audiocodec)="AC3 Audio"
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
    
    DisableGadget(#mp3mode,1)
    DisableGadget(#audibit,0)
    SetGadgetText(#text50,"Audio Bitrate:")
    SetGadgetText(#text51,"kbit/s")
    GadgetToolTip(#audibit,"Bitrate of audio")
    
  EndIf
  
  If GetGadgetText(#audiocodec)="FLAC Audio"
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
    
    DisableGadget(#mp3mode,1)
    DisableGadget(#audibit,1)
    SetGadgetText(#text50,"Audio Bitrate:")
    SetGadgetText(#text51,"kbit/s")
    GadgetToolTip(#audibit,"Useless for FLAC")
    
  EndIf
  
  If GetGadgetText(#audiocodec)="Copy Audio"
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
    SetGadgetState(#audibit,2)
    DisableGadget(#mp3mode,1)
    DisableGadget(#audibit,1)
  EndIf
  
  If GetGadgetText(#audiocodec)="AC3 Audio"
    
    ClearGadgetItems(#audibit)
    AddGadgetItem(#audibit,-1,"640")
    AddGadgetItem(#audibit,-1,"448")
    AddGadgetItem(#audibit,-1,"192")
    SetGadgetState(#audibit,1)
    
    ClearGadgetItems(#channel)
    AddGadgetItem(#channel,-1,"Original")
    AddGadgetItem(#channel,-1,"2")
    AddGadgetItem(#channel,-1,"1")
    
    
    SetGadgetText(#text50,"Audio Bitrate:")
    SetGadgetText(#text51,"kbit/s")
    
    SetGadgetState(#channel,0)
    
    DisableGadget(#mp3mode,1)
    DisableGadget(#audibit,0)
    
    GadgetToolTip(#audibit,"Bitrate of audio")
    
  EndIf
  
  
  If GetGadgetText(#audiocodec)="OGG Audio"
    
    DisableGadget(#mp3mode,1)
    DisableGadget(#audibit,0)
    SetGadgetText(#text50,"Audio Quality")
    SetGadgetText(#text51,"")
    
    ClearGadgetItems(#audibit)
    AddGadgetItem(#audibit,-1,"10")
    AddGadgetItem(#audibit,-1,"9")
    AddGadgetItem(#audibit,-1,"8")
    AddGadgetItem(#audibit,-1,"7")
    AddGadgetItem(#audibit,-1,"6")
    AddGadgetItem(#audibit,-1,"5")
    AddGadgetItem(#audibit,-1,"4")
    AddGadgetItem(#audibit,-1,"3")
    AddGadgetItem(#audibit,-1,"2")
    AddGadgetItem(#audibit,-1,"1")
    AddGadgetItem(#audibit,-1,"0")
    SetGadgetState(#audibit,6)
    GadgetToolTip(#audibit,"Use higher values for better quality")
    
  EndIf
  
  
  
EndProcedure

Procedure start()
  
  
  If GetGadgetText(#encodewith)="Automatic Avisynth decoder" : x264avs() : EndIf
  
  If GetGadgetText(#encodewith)="Force decoding with FFVideoSource" : x264avs() : EndIf
  If GetGadgetText(#encodewith)="Force decoding with DirectShowSource" : x264avs() : EndIf
  If GetGadgetText(#encodewith)="Force decoding with DGSource" : x264avs() : EndIf
  
  If GetGadgetText(#encodewith)="lavf (need X264 with lavf support)" : x264lavf() : EndIf
  If GetGadgetText(#encodewith)="ffms (need X264 with ffms support)" : x264lavf() : EndIf
  If GetGadgetText(#encodewith)="avs (need X264 with avs support)" : x264lavf() : EndIf
  If GetGadgetText(#encodewith)="auto (need X264 with auto support)" : x264lavf() : EndIf
  
  If GetGadgetText(#encodewith)="X264 with DirectShowSupport (need special build of X264)" : x264dss() : EndIf
  
  If GetGadgetText(#encodewith)="Pipe X264 with ffmpeg" : x264ffmpegpipe() : EndIf
  If GetGadgetText(#encodewith)="Pipe X264 with mencoder" : x264mencoderpipe() : EndIf
  
  If GetGadgetText(#encodewith)="Pipe X264 with avs2yuv" : x264avs2yuvpipe() : EndIf
  
  If GetGadgetText(#encodewith)="mkfifo mencoder to X264" : mkfifomencoder() : EndIf
  
  
EndProcedure

Procedure makereport()
  
  If GetGadgetText(#queue)=""
    queue.l=1
    
    If GetGadgetText(#width)=""
      MessageRequester("MultiX264", "Attention!"+Chr(13)+Chr(10)+"Load file First!")
      ProcedureReturn
    EndIf
    
    queuecount.l=queuecount.l+1
    queue.l=1
    If GetGadgetText(#pass)="1 pass" : passx.l=1 : audioencoding() : start() : mux() :  EndIf
    If GetGadgetText(#pass)="2 pass"
      audioencoding()
      passx.l=2 : start()
      passx.l=3 : start()
      mux()
    EndIf
    If GetGadgetText(#pass)="CRF 1 pass" : passx.l=4 : audioencoding() : start()  : mux() :  EndIf
    If GetGadgetText(#pass)="QP 1 pass" : passx.l=8 : audioencoding() : start()  : mux() :  EndIf
  EndIf
  
  CreateFile(147,here.s+"Post_This_File.txt")
  
  WriteStringN(147,"[CODE]MultiX264 "+ver.s+" report")
  WriteStringN(147,"")
  WriteStringN(147,"Input File: "+inputfile.s+" ( "+GetGadgetText(#inputstring)+" )")
  WriteStringN(147,"")
  WriteStringN(147,GetGadgetText(#basicfile))
  WriteStringN(147,"Resized resolution: "+GetGadgetText(#width)+" / "+GetGadgetText(#height))
  WriteStringN(147,"Crop Values : "+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)+":"+GetGadgetText(#rightcrop)+":"+GetGadgetText(#bottomcrop))
  If GetGadgetState(#itu)=1 : WriteStringN(147,"Activate: Follow ITU Resizing") : EndIf
  If GetGadgetState(#anamorphic)=1 : WriteStringN(147,"Activate: Anamorphic Resize") : EndIf
  If GetGadgetState(#allowresize)=0 : WriteStringN(147,"No Resize & Crop: On") : EndIf
  WriteStringN(147,"")
  WriteStringN(147,"Encoding With: "+GetGadgetText(#encodewith))
  WriteStringN(147,"Container: "+GetExtensionPart(GetGadgetText(#outputstring)))
  WriteStringN(147,"Encoding Mode: "+GetGadgetText(#pass))
  WriteStringN(147,"Video Bitrate: "+GetGadgetText(#videokbits))
  WriteStringN(147,"Denoise Level: "+GetGadgetText(#denoise))
  WriteStringN(147,"Resizer : "+GetGadgetText(#resizer))
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
  
  MessageRequester("MultiX264","               ---> Post_This_File.txt <--- file created in "+Chr(13)+Chr(10)+Chr(10)+here.s+" folder")
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


Procedure startqueue()
  
  DeleteFile(workpath.s+"MultiX264.bat")
  
  CreateFile(666,workpath.s+"MultiX264.bat")
  WriteStringN(666,"")
  WriteStringN(666,GetGadgetText(#queue))
  CloseFile(666)
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+workpath.s+"MultiX264.bat"+Chr(34),workpath.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+workpath.s+"MultiX264.bat"+Chr(34),workpath.s)
  EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    RunProgram(workpath.s+"MultiX264.bat","",workpath.s)
  CompilerEndIf
  ClearGadgetItems(#queue)
  
EndProcedure


Procedure Dimb()
     
  Dimb.f=Val(GetGadgetText(#cds))*1024*1024
  bitrate1.f=((Dimb.f-framecount.l*24-Val(GetGadgetText(#audibit))*1000*tsec.l*0.128)/((tsec.l*0.128)/1024)/1000)/1024
  
  If GetGadgetText(#audiocodec)="Ogg Audio"
    bitrate1.f=((Dimb.f-framecount.l*24-Val(GetGadgetText(#audibit))*32*1000*tsec.l*0.128)/((tsec.l*0.128)/1024)/1000)/1024
  EndIf
  
  If GetGadgetText(#audiocodec)="Copy Audio"
    abit.l=448
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
  
  If mplayer.s="" : MessageRequester("Preview","Mplayer not found. Please install it otherwise will be impossible to use preview",#PB_MessageRequester_Ok) : EndIf
  
  vcrop.s="crop="+Str(twidth.l-Val(GetGadgetText(#leftcrop))-Val(GetGadgetText(#rightcrop)))+":"+Str(theight.l-Val(GetGadgetText(#topcrop))-Val(GetGadgetText(#bottomcrop)))+":"+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)
  
  If linux=#True
    Select LCase(GetExtensionPart(inputfile.s))
    Case "mkv"
      aid.s="-aid "+StringField(GetGadgetText(#audiotrack),1,":")
    Default
      aid.s="-aid "+Str(GetGadgetState(#audiotrack))
    EndSelect
  EndIf
  
  If windows=#True
    Select LCase(GetExtensionPart(inputfile.s))
    Case "mkv","evo","vob","mpeg","mpg","ts","m2t","m2ts"
      aid.s="-aid "+StringField(GetGadgetText(#audiotrack),1,":")
    Default
      aid.s="-aid "+Str(GetGadgetState(#audiotrack))
    EndSelect
  EndIf
  
  CreateFile(987,here.s+"mplayerpreview.bat")   ; assuming lavf demuxer due to ffmpeg analysis
  WriteString(987,mplayer.s+" demuxer lavf "+aid.s+" -vf "+vcrop.s+",scale="+GetGadgetText(#width)+":"+GetGadgetText(#height)+" -aspect "+GetGadgetText(#arcombo)+" "+Chr(34)+inputfile.s+Chr(34))
  CloseFile(987)
  
  RunProgram(mplayer.s," -demuxer lavf "+aid.s+" -vf "+vcrop.s+",scale="+GetGadgetText(#width)+":"+GetGadgetText(#height)+" -aspect "+GetGadgetText(#arcombo)+" "+Chr(34)+inputfile.s+Chr(34),here.s)
  
EndProcedure

Procedure autocrop()
  
  DeleteFile(here.s+"mplayer_deep.bat")
  DeleteFile(here.s+"mplayer_deep.log")  
  
  If inputfile.s=""
    MessageRequester("MultiX264","No input select!")
    ProcedureReturn
  EndIf
  
  If mplayer.s=""
    MessageRequester("MultiX264","No mplayer found"+Chr(13)+Chr(13)+"Please download/install mplayer")
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
    WriteString(987,mplayer.s+" -speed 100 -vo null -vf cropdetect=24:2 -nosound -frames 2500 -identify "+Chr(34)+inputfile.s+Chr(34)+" 1>mplayer_deep.log 2>MultiX264.log")
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
  
  SetGadgetText(#arerror,StrF((dar.f/(ValF(GetGadgetText(#width))/ValF(GetGadgetText(#height))))*100-100,4))
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
  
  
EndProcedure


Procedure silentresize()
  
  SetGadgetText(#width,Str(RoundByX(twidth.l/100*GetGadgetState(#trackwidth),16,#True)))
  silentscale()
  
EndProcedure

Procedure checkifo()
  
  ClearGadgetItems(#audiotrack)
  AddGadgetItem(#audiotrack,-1,"none")
  
  
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
      ;AddGadgetItem(#subs,-1,mess.s)
    EndIf
    
    If FindString(mess,"VIDEO:  MPEG2",0)
      videocodec.s="mpeg2"
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
  messinfo.s=messinfo.s+"Duration(sec): "+Str(tsec.l)
  
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

Procedure mkvinfo()
  
  
  ClearGadgetItems(#audiotrack)
  AddGadgetItem(#audiotrack,0,"none")
  
  Structure media
    trackid.l
    mediatype.s
    tag.s
  EndStructure
  
  Global Dim mkv.media(999)
  aa.l=0
  If windows=#True
    WAIT=RunProgram(GetPathPart(mkvmerge.s)+"mkvinfo.exe",Chr(34)+inputfile.s+Chr(34),here.s,#PB_Program_Open|#PB_Program_Read|#PB_Program_Hide)
  EndIf
  If linux=#True
    WAIT=RunProgram("mkvinfo",Chr(34)+inputfile.s+Chr(34),here.s,#PB_Program_Open|#PB_Program_Read|#PB_Program_Hide)
  EndIf
  
  CreateFile(999,here.s+"mkvinfo.bat")
  If windows=#True : WriteString(999,Chr(34)+GetPathPart(mkvmerge.s)+"mkvinfo.exe"+Chr(34)+" "+Chr(34)+inputfile.s+Chr(34)+" > mkvinfo.log") : EndIf
  If linux=#True  : WriteString(999,"mkvinfo " +Chr(34)+inputfile.s+Chr(34)+" > mkvinfo.log") : EndIf
  CloseFile(999)
  
  If windows=#True
    RunProgram(here.s+"mkvinfo.bat","",here.s,#PB_Program_Wait)
  EndIf
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"mkvinfo.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"mkvinfo.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  
  
  If ReadFile(999,here.s+"mkvinfo.log")
    While Eof(999)=0
      line.s=ReadString(999)
      If FindString(line.s,"+ Track number:",0)
        aa.l=Val(Trim(StringField(line.s,2,":")))
        mkv(Val(Trim(StringField(line.s,2,":"))))\trackid.l = Val(Trim(StringField(line.s,2,":")))
      EndIf
      If FindString(line.s,"Codec ID",0) And FindString(line.s,"V_",0)=0 : mkv(aa)\mediatype.s = Trim(StringField(line.s,2,":")) : EndIf
      If FindString(line.s," Language:",0) : mkv(aa)\tag.s = UCase(Trim(StringField(line.s,2,":"))) : EndIf
      If FindString(line.s,"Channels:",0) : mkv(aa)\tag.s = mkv(aa)\tag.s+", "+Trim(StringField(line.s,2,":"))+" channels" : EndIf
      If FindString(line.s,"Sampling frequency:",0) : mkv(aa)\tag.s = mkv(aa)\tag.s+", "+Trim(StringField(line.s,2,":"))+" hz" : EndIf
      If FindString(line.s,"Chapter",0) : chaptersmkv.l=1 : EndIf
    Wend
  EndIf
  
  For bb=1 To aa
    If FindString(mkv(bb)\mediatype.s,"A_",0)
      AddGadgetItem(#audiotrack,-1,Str(mkv(bb)\trackid.l)+": "+mkv(bb)\mediatype.s+" "+mkv(bb)\tag.s)
      Debug(Str(mkv(bb)\trackid.l)+": "+mkv(bb)\mediatype.s+" "+mkv(bb)\tag.s)
    EndIf
  Next bb
  
  SetGadgetState(#audiotrack,1)
  
  
EndProcedure


Procedure eac3toanalyzeaudio()
  
  ClearGadgetItems(#audiotrack)
  AddGadgetItem(#audiotrack,0,"none")
  DeleteFile(here.s+"eac3toinfo.log")
  
  CreateFile(987,here.s+"eac3to.bat")
  WriteStringN(987,eac3to.s+" "+Chr(34)+inputfile.s+Chr(34)+" -log="+Chr(34)+here.s+"eac3toinfo.log"+Chr(34))
  CloseFile(987)
  RunProgram(here.s+"eac3to.bat","",here.s,1)
  
  If ReadFile(865,here.s+"eac3toinfo.log")
    While Eof(865)=#False
      mess.s=ReplaceString(LCase(ReadString(865)),Chr(8),"")
      
      If LCase(GetExtensionPart(inputfile.s))<>"d2v" And LCase(GetExtensionPart(inputfile.s))<>"dga" And LCase(GetExtensionPart(inputfile.s))<>"avs" And LCase(GetExtensionPart(inputfile.s))<>"dgi" And LCase(GetExtensionPart(inputfile.s))<>"dgm" And LCase(GetExtensionPart(inputfile.s))<>"dgv"
        Debug(mess.s)
        If FindString(mess.s,"cha",0) And FindString(mess.s,".",0) And FindString(mess.s,"embedded:",0)=0 And FindString(mess.s,"core:",0)=0 And FindString(mess.s,Chr(34),0)=0
          AddGadgetItem(#audiotrack,-1,Trim(mess.s))
        EndIf
      EndIf
    Wend
    
    CloseFile(865)
    
  EndIf
  
  
EndProcedure


Procedure ffmpeganalyzeaudio()
  
  ClearGadgetItems(#audiotrack)
  AddGadgetItem(#audiotrack,0,"none")
  
  DeleteFile(here.s+"ffmpeganalysis.bat")
  DeleteFile(here.s+"ffmpeganalysis.txt")
  CreateFile(987,here.s+"ffmpeganalysis.bat")
  WriteString(987,ffmpeg.s+" -i "+Chr(34)+inputfile.s+Chr(34)+" 2>"+Chr(34)+here.s+"ffmpeganalysis.txt"+Chr(34))
  CloseFile(987)
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"ffmpeganalysis.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"ffmpeganalysis.bat"+Chr(34),here.s,#PB_Program_Wait)
  Else
    RunProgram(here.s+"ffmpeganalysis.bat","",here.s,#PB_Program_Wait)
  EndIf
  
  Delay(500)
  
  fh=ReadFile(#PB_Any,here.s+"ffmpeganalysis.txt")
  While Eof(fh)=0
    mess.s=ReadString(fh)
    If FindString(mess.s,"Audio: ",0)
      AddGadgetItem(#audiotrack,-1,Trim(mess.s))
    EndIf
    If FindString(mess.s,"fps",0)
      ffps.f=ValF((StringField(StringField(mess.s,6,","),2," ")))
    EndIf
    If FindString(mess.s,"x",0) And FindString(mess.s,"Video:",0)
      ffh.f=ValF((StringField(StringField(StringField(mess.s,3,","),2,"x"),1," ")))
      ffw.f=ValF((StringField(StringField(StringField(mess.s,3,","),1,"x"),2," ")))
    EndIf
    If FindString(mess.s,"Duration:",0)
      fhour.f=ValF((StringField(mess.s,2,":")))
      fmin.f=ValF((StringField(mess.s,3,":")))
      fsec.f=ValF((StringField(mess.s,4,":")))
      ftsec.l=Int(fthour.f*3600+fmin.f*60+fsec.f)
    EndIf
    
  Wend
  
  CloseFile(fh)
  
  
  SetGadgetState(#audiotrack,1)
  
  
EndProcedure


Procedure checkmedia()
  
  ClearGadgetItems(#audiotrack)
  
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
  checkfile.s=inputfile.s
  
  DeleteFile(here.s+"mplayer.log")
  DeleteFile(here.s+"mplayer.bat")
  DeleteFile(here.s+"multix264.log")
  
  CreateFile(987,here.s+"analyze.bat")
  
  If linux=#True
    WriteString(987,ffmpeg.s+" -i "+Chr(34)+checkfile.s+Chr(34)+" -vf select='not(mod(n\,100))',cropdetect -an -y deleteme.avi 2>ffmpeg.log")
  Else
    WriteString(987,ffmpeg.s+" -i "+Chr(34)+checkfile.s+Chr(34)+" -vf select=not(mod(n\,100)),cropdetect -an -y deleteme.avi 2>ffmpeg.log")
  EndIf
  
  CloseFile(987)
  
  If windows=#True
    RunProgram(here.s+"analyze.bat","",here.s,#PB_Program_Wait)
  EndIf
  If linux=#True
    RunProgram("chmod","+x "+Chr(34)+here.s+"analyze.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"analyze.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  
  fh=OpenFile(#PB_Any,here.s+"ffmpeg.log")
  
  While Eof(fh)=0
    mess.s=ReadString(fh)
    
    If FindString(mess,"mpeg2video",0)
      videocodec.s="mpeg2"
    EndIf
    If FindString(mess,"h264",0)
      videocodec.s="h264"
    EndIf
    If FindString(mess,"mjpeg",0)
      videocodec.s="mjpeg"
    EndIf
    If FindString(mess,"dvvideo",0)
      videocodec.s="dv"
    EndIf
    If FindString(mess,"lagarith",0)
      videocodec.s="lagarith"
    EndIf
    If FindString(mess,"mpeg4",0)
      videocodec.s="mpeg4"
    EndIf
    If FindString(mess,"DAR ",0)
      aa.l=FindString(mess.s,"DAR",0)
      ar.s=StrF(ValF(StringField(StringField(StringField(Mid(mess.s,aa,1000),1,","),2," "),1,":"))/ValF(StringField(StringField(StringField(Mid(mess.s,aa,1000),1,","),2," "),2,":")),4)
    EndIf
    If FindString(mess,"DAR 16:9]",0)
      ar.s="1.7778"
    EndIf
    If FindString(mess,"DAR 4:3]",0)
      ar.s="1.3334"
    EndIf
    If FindString(mess,"DAR 1:1]",0)
      ar.s="1"
    EndIf
    If FindString(mess.s,"fps,",0)
      aa.l=FindString(mess.s,"fps,",0)
      framerate.f=ValF(StringField(StringField(Mid(mess.s,aa,1000),2,","),2," "))
    EndIf
    If FindString(mess.s,"25 tbr,",0)
      tbr.f=25
    EndIf
    If FindString(mess.s,"24 tbr,",0)
      tbr.f=24
    EndIf
    If FindString(mess.s,"29.97 tbr,",0)
      tbr.f=29.97
    EndIf
    If FindString(mess.s,"23.98 tbr,",0)
      tbr.f=23.976
    EndIf
    If FindString(mess.s,"30 tbr,",0)
      tbr.f=30
    EndIf
    If FindString(mess.s,"50 tbr,",0)
      tbr.f=50
    EndIf
    If FindString(mess.s,"60 tbr,",0)
      tbr.f=60
    EndIf
    
    If FindString(mess.s,"x",0) And FindString(mess.s,"Video:",0)
      theight.l=Val((StringField(StringField(StringField(mess.s,3,","),2,"x"),1," ")))
      twidth.l=Val((StringField(StringField(StringField(mess.s,3,","),1,"x"),2," ")))
    EndIf
    If FindString(mess.s,"Stream",0) And FindString(mess.s,"Video:",0)  And FindString(mess.s,"720x576",0)
      theight.l=576
      twidth.l=720
    EndIf
    If FindString(mess.s,"Stream",0) And FindString(mess.s,"Video:",0)  And FindString(mess.s,"1920x1080",0)
      theight.l=1080
      twidth.l=1920
    EndIf
    
    If FindString(mess.s,"Duration:",0)
      fhour.f=ValF((StringField(mess.s,2,":")))
      fmin.f=ValF((StringField(mess.s,3,":")))
      fsec.f=ValF((StringField(mess.s,4,":")))
      tsec.l=Int(fthour.f*3600+fmin.f*60+fsec.f)
    EndIf
    
    If FindString(mess.s,"cropdetect",0)
      ; pdetect @ 03702BC0] x1:0 x2:695 y1:2 y2:573 w:688 h:560 x:4 y:8 pos:2811918 pts:6512000 t:6.512000 crop=688:560:4:8"
      mess4.s=StringField(mess.s,2,"=")
      actop.l=Val(StringField(mess4.s,4,":"))
      acleft.l=Val(StringField(mess4.s,3,":"))
      acright.l=twidth.l-Val(StringField(mess4.s,1,":"))-Val(StringField(mess4.s,3,":"))
      acbottom.l=theight.l-Val(StringField(mess4.s,2,":"))-Val(StringField(mess4.s,4,":"))
      crop.s=StringField(mess.s,2,"=")
    EndIf
    
    If FindString(mess.s,"Audio: ",0) And FindString(mess.s,"Stream",0)
      AddGadgetItem(#audiotrack,-1,Trim(mess.s))
    EndIf
    
  Wend
  
  CloseFile(fh)
  
  ;audio check
  
  If linux=#True
    Select LCase(GetExtensionPart(inputfile.s))
    Case "mkv"
      mkvinfo()
    EndSelect
  EndIf
  
  
  If windows=#True
    Select LCase(GetExtensionPart(inputfile.s))
    Case "evo","vob","mpeg","mpg","ts","m2t","m2ts"
      If eac3to.s<>""
        eac3toanalyzeaudio()
      EndIf
    Case "mkv"
      If eac3to.s<>""
        eac3toanalyzeaudio()
      EndIf
      If eac3to.s=""
        mkvinfo()
      EndIf
    EndSelect
  EndIf
  
  If framerate.f=0 : framerate.f=tbr.f : EndIf
  
  ;ffmpeg rounding error
  
  If framerate>23.900 And framerate<23.99
    framerate.f=23.976
  EndIf
  
  If framerate.f<>25 And framerate.f<>23.976  And framerate.f<>29.97 And framerate.f<>50 And framerate.f<>60 And framerate.f<>30 And framerate.f<>24 And framerate.f<>59.94
    framerate.f=Round(framerate.f,#PB_Round_Nearest)
  EndIf
  
  framecount.l=tsec.l*framerate.f
  
  If FindString(ar.s,"/",0) : ar.s=StrF(ValF(StringField(ar.s,1,"/"))/ValF(StringField(ar.s,2,"/"))) : EndIf
  
  SetGadgetText(#arcombo,ar.s)
  
  If CountGadgetItems(#audiotrack)>1 : SetGadgetState(#audiotrack,1) : EndIf
  If CountGadgetItems(#audiotrack)<=1 : SetGadgetState(#audiotrack,0) : EndIf
  If tsec.l > 1 : SetGadgetText(#videolenght,StrF(tsec.l/60,3)) : EndIf
  
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
    videocodec.s="mpeg2"
  EndIf
  
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="dgi"
    fh = ReadFile(#PB_Any,GetGadgetText(#inputstring))
    While Eof(fh) = #False
      line.s = ReadString(fh)
      If FindString(line.s,"SIZ ",0)
        twidth.l=Val(Trim(StringField(StringField(line.s,1,"x"),2," ")))
        theight.l=Val(Trim(StringField(StringField(line.s,2,"x"),2," ")))
      EndIf
      If FindString(line.s,"CODED ",0)
        framecount.l=Val(Trim(StringField(line.s,2," ")))
      EndIf
      If FindString(line.s,"%",0) And FindString(line.s,"FILM",0)
        perffilm.f=ValF(StringField(line.s,1,"%"))
        If perffilm.f>97
          result=MessageRequester("MultiX264","The dgi report a "+StrF(perffilm.f,2)+" of film"+Chr(10)+"Would activate IVTC deinterlace?",#PB_MessageRequester_YesNo)
          If result=#PB_MessageRequester_Yes : SetGadgetText(#mdeint,"FILM NTSC (29.97->23.976)") : EndIf
        EndIf
      EndIf
    Wend
    CloseFile(fh)
    videocodec.s="h264"
  EndIf
  
  
  If GetExtensionPart(LCase(GetGadgetText(#inputstring)))="dga"
    fh = ReadFile(#PB_Any,GetGadgetText(#inputstring))
    While Eof(fh) = #False
      line.s = ReadString(fh)
      If FindString(line.s,"SIZ ",0)
        twidth.l=Val(Trim(StringField(StringField(line.s,1,"x"),2," ")))
        theight.l=Val(Trim(StringField(StringField(line.s,2,"x"),2," ")))
      EndIf
      If FindString(line.s,"FPS ",0)
        framerate.f=ValF(Trim(StringField(StringField(line.s,1,"/"),2," ")))/ValF(Trim(StringField(StringField(line.s,2,"/"),2," ")))
      EndIf
      If FindString(line.s,"CODED ",0)
        framecount.l=Val(Trim(StringField(line.s,2," ")))
      EndIf
      If FindString(line.s,"%",0) And FindString(line.s,"FILM",0)
        perffilm.f=ValF(StringField(line.s,1,"%"))
        If perffilm.f>97
          result=MessageRequester("MultiX264","The dga report a "+StrF(perffilm.f,2)+" of film"+Chr(10)+"Would activate IVTC deinterlace?",#PB_MessageRequester_YesNo)
          If result=#PB_MessageRequester_Yes : SetGadgetText(#mdeint,"FILM NTSC (29.97->23.976)") : EndIf
        EndIf
      EndIf
    Wend
    CloseFile(fh)
    videocodec.s="h264"
  EndIf
  
  
  If GetGadgetText(#arcombo)="" : SetGadgetText(#arcombo,StrF(twidth.l/theight.l,4)) : EndIf
  
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
  
  If ar.s="" : ar.s=StrF(twidth.l/theight.l,4) : EndIf
  
  Debug("twidth.l="+Str(twidth.l))
  Debug("theight.l="+Str(theight.l))
  Debug("framerate.f="+StrF(framerate.f))
  Debug("framecount.l="+Str(tsec.l*framerate.f))
  Debug("tsec.l="+Str(tsec.l))
  Debug("ar.s"=ar.s)
  If tsec.l<5 : tsec.l=framecount.l/framerate.f : EndIf
  
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
  messinfo.s=messinfo.s+"Aspect Ratio: "+ar.s
  
  SetGadgetText(#basicfile,messinfo.s)
  
  If framerate.f=59.940 Or framerate.f=29.97
    result=MessageRequester("MultiX264","Possible Telecine pattern found."+Chr(13)+Chr(13)+"Allow IVTC ? FILM NTSC (29.97->23.976)",#PB_MessageRequester_YesNo)
    If result=#PB_MessageRequester_Yes : SetGadgetText(#mdeint,"FILM NTSC (29.97->23.976)") : EndIf
  EndIf
  
  dimb()
  
  silentresize()
  
  
EndProcedure


Procedure allowresize()
  
  ;don't ask why , linux seems to have problems with this routine
  
  If twidth.l<=0 : twidth.l=0 : EndIf
  If theight.l<=0 : theight.l=0 : EndIf
  
  
  If GetGadgetState(#allowresize)=#PB_Checkbox_Unchecked
    SetGadgetText(#width,Str(twidth.l))
    SetGadgetText(#height,Str(theight.l))
    DisableGadget(#topcrop,1)
    DisableGadget(#rightcrop,1)
    DisableGadget(#bottomcrop,1)
    DisableGadget(#leftcrop,1)
    DisableGadget(#width,1)
    DisableGadget(#height,1)
  Else
    DisableGadget(#topcrop,0)
    DisableGadget(#rightcrop,0)
    DisableGadget(#bottomcrop,0)
    DisableGadget(#leftcrop,0)
    DisableGadget(#width,0)
    DisableGadget(#height,0)
  EndIf
  
  
  
EndProcedure

Procedure checkx264mod()
  
  If GetGadgetText(#x264mod)<>""
    If FindString(GetGadgetText(#x264mod),"preset",0)
      SetGadgetText(#preset,"No Preset")
    EndIf
    If FindString(GetGadgetText(#x264mod),"tune",0)
      SetGadgetText(#tuning,"none")
    EndIf
  EndIf
  
EndProcedure

Procedure openinputfile()
  
  Debug("last="+last.s)
  
  If linux=#True
    
    StandardFile$ = "input.mkv"
    Pattern$ = "Supported files|*.avi;*.ogm;*.mkv;*.m2ts;*.vob;*.mpeg;*.pvr;*.mpg;*.ogm;*.ts;*.vro;*.divx;*.m2t|All files (*.*)|*.*"
    Pattern = 0    ; use the first of the three possible patterns as standard
    inputfile.s = OpenFileRequester("Please choose file to load", StandardFile$, Pattern$, Pattern)
  Else
    inputfile.s=OpenFileRequester("Open File to Encode", last.s, "Supported Movie File|*VOB;*.EVO;*.M2TS;*.TS;*.MTS;*.MKV;*.OGM;*.MPG;*.MPEG;*.AVS;*.AVI;*.M2T;*.VRO;*.D2V;*.DGA;*.AVS;*.GRF;*.DGM;*.DGV;*.MOV;video_ts.IFO;*.OGV;*.MP4;*.FLV|All files|*.*",0)
  EndIf
  
  If inputfile.s<>""
    SetGadgetText(#inputstring,inputfile.s)
    framecount.l=0
    framerate.f=0
    twidth.l=0
    theight.l=0
    StatusBarText(#statusbar, 0,"")
    start.l=1
    
    exts.s=LCase(GetExtensionPart(inputfile.s))
    If exts.s<>"ifo"
      checkmedia()
    EndIf
    If exts.s="ifo"
      checkifo()
    EndIf
    
    SetGadgetState(#trackwidth,87)
    silentresize()
  EndIf
  
  
EndProcedure



Open_Window_0()
here.s=GetCurrentDirectory()

CompilerIf #PB_Compiler_OS = #PB_OS_Linux : linux=#True : CompilerEndIf
CompilerIf #PB_Compiler_OS = #PB_OS_Windows : windows=#True : CompilerEndIf

x264.s=""
mplayer.s=""
mencoder.s=""
mkvmerge.s=""
mp4box.s=""
ffmpeg.s=""
avs2yuv.s=""

SetGadgetState(#allowresize,1)

If linux=#True
  
  If FileSize("/usr/bin/x264")<>-1  : x264.s="/usr/bin/x264" : EndIf
  If FileSize("/usr/local/bin/x264")<>-1 : x264.s="/usr/local/bin/x264" : EndIf
  
  If FileSize("/usr/bin/mplayer")<>-1  : mplayer.s="/usr/bin/mplayer" : EndIf
  If FileSize("/usr/local/bin/mplayer")<>-1 : mplayer.s="/usr/local/bin/mplayer" : EndIf
  
  If FileSize("/usr/bin/mencoder")<>-1  : mencoder.s="/usr/bin/mencoder" : EndIf
  If FileSize("/usr/local/bin/mencoder")<>-1 : mencoder.s="/usr/local/bin/mencoder" : EndIf
  
  If FileSize("/usr/bin/mkvmerge")<>-1  : mkvmerge.s="/usr/bin/mkvmerge" : EndIf
  If FileSize("/usr/local/bin/mkvmerge")<>-1 : mkvmerge.s="/usr/local/bin/mkvmerge" : EndIf
  
  If FileSize("/usr/bin/mkvinfo")<>-1  : mkvinfo.s="/usr/bin/mkvinfo" : EndIf
  If FileSize("/usr/local/bin/mkvinfo")<>-1 : mkvinfo.s="/usr/local/bin/mkvinfo" : EndIf
  
  If FileSize("/usr/bin/MP4Box")<>-1  : mp4box.s="/usr/bin/mp4box" : EndIf
  If FileSize("/usr/local/bin/MP4Box")<>-1 : mp4box.s="/usr/local/bin/mp4box" : EndIf
  
  If FileSize("/usr/bin/ffmpeg")<>-1  : ffmpeg.s="/usr/bin/ffmpeg" : EndIf
  If FileSize("/usr/local/bin/ffmpeg")<>-1 : ffmpeg.s="/usr/local/bin/ffmpeg" : EndIf
  
  If FileSize("/usr/bin/avs2yuv.exe")<>-1  : avs2yuv.s="/usr/bin/avs2yuv.exe" : EndIf
  If FileSize("/usr/local/bin/avs2yuv.exe")<>-1 : avs2yuv.s="/usr/local/bin/avs2yuv.exe" : EndIf
  If FileSize("/usr/bin/avs2yuv")<>-1  : avs2yuv.s="/usr/bin/avs2yuv" : EndIf
  If FileSize("/usr/local/bin/avs2yuv")<>-1 : avs2yuv.s="/usr/local/bin/avs2yuv" : EndIf
  
  If FileSize("/usr/bin/flac")<>-1  : flac.s="/usr/bin/flac" : EndIf
  If FileSize("/usr/local/bin/flac")<>-1 : flac.s="/usr/local/bin/flac" : EndIf
  
  If FileSize("/usr/bin/faac")<>-1  : flac.s="/usr/bin/faac" : EndIf
  If FileSize("/usr/local/bin/faac")<>-1 : flac.s="/usr/local/bin/faac" : EndIf
  
  If FileSize("/usr/bin/lame")<>-1  : lame.s="/usr/bin/lame" : EndIf
  If FileSize("/usr/local/bin/lame")<>-1 : lame.s="/usr/local/bin/lame" : EndIf
  
  If FileSize("/usr/bin/oggenc")<>-1  : oggenc.s="/usr/bin/oggenc" : EndIf
  If FileSize("/usr/local/bin/oggenc")<>-1 : oggenc.s="/usr/local/bin/oggenc" : EndIf
  
  If FileSize("/usr/bin/oggenc2")<>-1  : oggenc.s="/usr/bin/oggenc2" : EndIf
  If FileSize("/usr/local/bin/oggenc2")<>-1 : oggenc.s="/usr/local/bin/oggenc2" : EndIf
  
  If FileSize("/usr/bin/aften")<>-1  : aften.s="/usr/bin/aften" : EndIf
  If FileSize("/usr/local/bin/aften")<>-1 : aften.s="/usr/local/bin/aften" : EndIf
  
  If FileSize("/usr/bin/faad")<>-1  : faad.s="/usr/bin/faad" : EndIf
  If FileSize("/usr/local/bin/faad")<>-1 : faad.s="/usr/local/bin/faad" : EndIf
  
  If FileSize("/usr/bin/neroAacEnc")<>-1  : neroAacEnc.s="/usr/bin/neroAacEnc" : EndIf
  If FileSize("/usr/local/bin/neroAacEnc")<>-1 : neroAacEnc.s="/usr/local/bin/neroAacEnc" : EndIf
  
EndIf


If windows=#True
  
  If FileSize(here.s+"x264.exe")<>-1 : x264.s=Chr(34)+here.s+"x264.exe"+Chr(34) : EndIf
  If FileSize(here.s+"mplayer.exe")<>-1 : mplayer.s=Chr(34)+here.s+"mplayer.exe"+Chr(34) : EndIf
  If FileSize(here.s+"mencoder.exe")<>-1 : mencoder.s=Chr(34)+here.s+"mencoder.exe"+Chr(34) : EndIf
  If FileSize(here.s+"mkvmerge.exe")<>-1 : mkvmerge.s=Chr(34)+here.s+"mkvmerge.exe"+Chr(34) : EndIf
  If FileSize(here.s+"mp4box.exe")<>-1 : mp4box.s=Chr(34)+here.s+"mp4box.exe"+Chr(34) : EndIf
  If FileSize(here.s+"ffmpeg.exe")<>-1 : ffmpeg.s=Chr(34)+here.s+"ffmpeg.exe"+Chr(34) : EndIf
  If FileSize(here.s+"eac3to.exe")<>-1 : eac3to.s=Chr(34)+here.s+"eac3to.exe"+Chr(34) : EndIf
  If FileSize(here.s+"avs2yuv.exe")<>-1 : avs2yuv.s=Chr(34)+here.s+"avs2yuv.exe"+Chr(34) : EndIf
  If FileSize(here.s+"faad.exe")<>-1 : faad.s=Chr(34)+here.s+"faad.exe"+Chr(34) : EndIf
  If FileSize(here.s+"aften.exe")<>-1 : aften.s=Chr(34)+here.s+"aften.exe"+Chr(34) : EndIf
  If FileSize(here.s+"flac.exe")<>-1 : flac.s=Chr(34)+here.s+"flac.exe"+Chr(34) : EndIf
  If FileSize(here.s+"oggenc.exe")<>-1 : oggenc.s=Chr(34)+here.s+"oggenc.exe"+Chr(34) : EndIf
  If FileSize(here.s+"oggenc2.exe")<>-1 : oggenc.s=Chr(34)+here.s+"oggenc2.exe"+Chr(34) : EndIf
  If FileSize(here.s+"faac.exe")<>-1 : faac.s=Chr(34)+here.s+"faac.exe"+Chr(34) : EndIf
  If FileSize(here.s+"neroaacenc.exe")<>-1 : neroaacenc.s=Chr(34)+here.s+"neroaacenc.exe"+Chr(34) : EndIf
  
  If FileSize(here.s+"applications\mplayer\mplayer.exe")<>-1 : mplayer.s=Chr(34)+here.s+"applications\mplayer\mplayer.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\mplayer\mencoder.exe")<>-1 : mencoder.s=Chr(34)+here.s+"applications\mplayer\mencoder.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\mkvtoolnix\mkvmerge.exe")<>-1 : mkvmerge.s=Chr(34)+here.s+"applications\mkvtoolnix\mkvmerge.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\mkvtoolnix\mkvinfo.exe")<>-1 : mkvinfo.s=Chr(34)+here.s+"applications\mkvtoolnix\mkvinfo.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\mp4box\mp4box.exe")<>-1 : mp4box.s=Chr(34)+here.s+"applications\mp4box\mp4box.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\ffmpeg\ffmpeg.exe")<>-1 : ffmpeg.s=Chr(34)+here.s+"applications\ffmpeg\ffmpeg.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\x264\x264.exe")<>-1 : x264.s=Chr(34)+here.s+"applications\x264\x264.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\eac3to\eac3to.exe")<>-1 : eac3to.s=Chr(34)+here.s+"applications\eac3to\eac3to.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\avs2yuv\avs2yuv.exe")<>-1 : avs2yuv.s=Chr(34)+here.s+"applications\avs2yuv\avs2yuv.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\faad\faad.exe")<>-1 : faad.s=Chr(34)+here.s+"applications\faad\faad.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\aften\aften.exe")<>-1 : aften.s=Chr(34)+here.s+"applications\aften\aften.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\flac\flac.exe")<>-1 : flac.s=Chr(34)+here.s+"applications\flac\flac.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\lame\lame.exe")<>-1 : lame.s=Chr(34)+here.s+"applications\lame\lame.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\oggenc\oggenc.exe")<>-1 : oggenc.s=Chr(34)+here.s+"applications\oggenc\oggenc.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\oggenc\oggenc2.exe")<>-1 : oggenc.s=Chr(34)+here.s+"applications\oggenc\oggenc2.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\faac\faac.exe")<>-1 : faac.s=Chr(34)+here.s+"applications\faac\faac.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\neroaacenc\neroaacenc.exe")<>-1 : neroaacenc.s=Chr(34)+here.s+"applications\neroaacenc\neroaacenc.exe"+Chr(34) : EndIf
  
  ; path using megui folders ->
  
  If FileSize(here.s+"tools\mencoder\mplayer.exe")<>-1 : mplayer.s=Chr(34)+here.s+"tools\mencoder\mplayer.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\mencoder\mencoder.exe")<>-1 : mencoder.s=Chr(34)+here.s+"tools\mencoder\mencoder.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\mkvmerge\mkvmerge.exe")<>-1 : mkvmerge.s=Chr(34)+here.s+"tools\mkvmerge\mkvmerge.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\mkvmerge\mkvinfo.exe")<>-1 : mkvinfo.s=Chr(34)+here.s+"tools\mkvmerge\mkvinfo.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\mp4box\mp4box.exe")<>-1 : mp4box.s=Chr(34)+here.s+"tools\mp4box\mp4box.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\ffmpeg\ffmpeg.exe")<>-1 : ffmpeg.s=Chr(34)+here.s+"tools\ffmpeg\ffmpeg.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\x264\x264.exe")<>-1 : x264.s=Chr(34)+here.s+"tools\x264tools.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\eac3to\eac3to.exe")<>-1 : eac3to.s=Chr(34)+here.s+"applications\eac3to\eac3to.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\avs2yuv\avs2yuv.exe")<>-1 : avs2yuv.s=Chr(34)+here.s+"tools\avs2yuv\avs2yuv.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\faad\faad.exe")<>-1 : faad.s=Chr(34)+here.s+"tools\faad\faad.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\aften\aften.exe")<>-1 : aften.s=Chr(34)+here.s+"tools\aften\aften.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\flac\flac.exe")<>-1 : flac.s=Chr(34)+here.s+"tools\flac\flac.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\lame\lame.exe")<>-1 : lame.s=Chr(34)+here.s+"tools\lame\lame.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\oggenc\oggenc.exe")<>-1 : oggenc.s=Chr(34)+here.s+"tools\oggenc\oggenc.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\oggenc\oggenc2.exe")<>-1 : oggenc.s=Chr(34)+here.s+"tools\oggenc\oggenc2.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\faac\faac.exe")<>-1 : faac.s=Chr(34)+here.s+"tools\faac\faac.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\neroaacenc\neroaacenc.exe")<>-1 : neroaacenc.s=Chr(34)+here.s+"tools\neroaacenc\neroaacenc.exe"+Chr(34) : EndIf
  
EndIf

If ffmpeg.s="" :   MessageRequester("FFmpeg", "No FFmpeg found on path. Please install it. Quitting...", #PB_MessageRequester_Ok) : End:  EndIf
If x264.s="" :     MessageRequester("X264", "No X264 found on path. Please install it. Quitting...", #PB_MessageRequester_Ok) : End:  EndIf
If mplayer.s="" :  MessageRequester("Mplayer", "No Mplayer found on path. Please install it. Otherwise will be impossibile to preview video or analyze DVD", #PB_MessageRequester_Ok) : EndIf
If mp4box.s="" :   MessageRequester("Muxer", "No MP4Box (gpac) found on path. Please install it otherwise will be impossibile to mux on MP4", #PB_MessageRequester_Ok) : EndIf
If mkvmerge.s="" : MessageRequester("Muxer", "No MKVtoolnix found on path. Please install it. Quitting...", #PB_MessageRequester_Ok) : End : EndIf

If windows=#True
  
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"Automatic Avisynth decoder") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"auto (need X264 with auto support)") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"avs (need X264 with avs support)") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"ffms (need X264 with ffms support)") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"lavf (need X264 with lavf support)") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"Force decoding with FFVideoSource") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"Force decoding with DirectShowSource") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"Force decoding with DGSource") : EndIf
  If x264.s<>"" :  AddGadgetItem(#encodewith,-1,"X264 with DirectShowSupport (need special build of X264)") : EndIf
  
EndIf


If linux=#True
  
  If x264.s<>""
    CreateFile(987,here.s+".x264check")
    WriteString(987,"x264 --fullhelp | grep support >"+Chr(34)+here.s+".x264supp"+Chr(34))
    CloseFile(987)
    
    RunProgram("chmod","+x "+Chr(34)+here.s+".x264check"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+".x264check"+Chr(34),here.s,#PB_Program_Wait)
    
    If FileSize(here.s+".x264supp")<>-1
      ReadFile(fh,here.s+".x264supp")
      While Eof(fh)=#False
        line.s=ReadString(fh)
        If FindString(line.s,"lavf support (yes)",0)
          AddGadgetItem(#encodewith,-1,"lavf (need X264 with lavf support)")
          AddGadgetItem(#encodewith,-1,"auto (need X264 with auto support)")
        EndIf
        If FindString(line.s,"ffms support (yes)",0)
          AddGadgetItem(#encodewith,-1,"ffms (need X264 with ffms support)")
        EndIf
      Wend
      CloseFile(fh)
    EndIf
  EndIf
EndIf

If ffmpeg.s<>"" And x264.s<>"" :   AddGadgetItem(#encodewith,-1,"Pipe X264 with ffmpeg") : EndIf
If mencoder.s<>"" And x264.s<>"" : AddGadgetItem(#encodewith,-1,"Pipe X264 with mencoder") : EndIf
If avs2yuv.s<>"" And x264.s<>"" :  AddGadgetItem(#encodewith,-1,"Pipe X264 with avs2yuv") : EndIf


If linux=#True And mencoder.s<>"" And x264.s<>"" : AddGadgetItem(#encodewith,-1,"mkfifo mencoder to X264") : EndIf

SetGadgetState(#encodewith,0)
handbrakeoff()
StatusBarText(#statusbar, 0, "If you like MultiX264, please consider a donation")

If FileSize(here.s+"HDConvertToX_profile.txt")<>-1
  ReadFile(fh,here.s+"HDConvertToX_profile.txt")
  While Eof(fh)=#False
    line.s=ReadString(fh)
    If FindString(line.s,"X264;",0) : AddGadgetItem(#x264mod,-1,StringField(line.s,4,";")) : EndIf
  Wend
  CloseFile(fh)
EndIf

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
      
      If GetGadgetText(#outputstring)=""
        If mkvmerge.s<>"" : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"multix264_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mkv") : EndIf
        If mkvmerge.s="" And mp4box.s<>""
          SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"MultiX264_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mp4")
        EndIf
        If mkvmerge.s="" And mp4box.s=""
          SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"MultiX264_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".h264")
        EndIf
        outputfile.s=GetGadgetText(#outputstring)
      EndIf
      
      
    ElseIf GadgetID = #save
      mess.s=GetCurrentDirectory()
      If inputfile.s<>"" : mess.s=GetPathPart(inputfile.s) : EndIf
      outputfile.s=SaveFileRequester("Save output file",GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))+"_MX","*.mkv|*.mkv|*.mp4|*.mp4|*.h264|*.h264",0)
      index=SelectedFilePattern()
      If outputfile.s<>""
        If index=0 : outputfile.s=outputfile.s+".mkv" : EndIf
        If index=1 : outputfile.s=outputfile.s+".mp4" : EndIf
        If index=2 : outputfile.s=outputfile.s+".h264" : EndIf
        SetGadgetText(#outputstring,outputfile.s)
      EndIf
      If outputfile.s : SetGadgetText(#outputstring,outputfile.s) : EndIf
      
    ElseIf GadgetID = #audiocodec
      handbrakeoff()
      
    ElseIf GadgetID = #preview
      preview()
      
    ElseIf GadgetID = #play
      RunProgram(mplayer.s,Chr(34)+inputfile.s+Chr(34),here.s)
      
    ElseIf GadgetID = #cds
      Dimb()
      sanitycheck()
      
    ElseIf GadgetID = #makereport
      makereport()
      
    ElseIf GadgetID = #x264mod
      checkx264mod()
      
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
      If FindString(GetGadgetText(#pass),"QP",0) :  SetGadgetText(#Text_33,"Quant") :  DisableGadget(#cds,1) : SetGadgetText(#Text_32,"Quality") : EndIf
      If FindString(GetGadgetText(#pass),"CRF",0)=0 : SetGadgetText(#Text_33,"kbp/s") : DisableGadget(#cds,0) : SetGadgetText(#Text_32,"Video Bitrate") : EndIf
      
      
    ElseIf GadgetID = #allowresize
      allowresize()
      
    ElseIf GadgetID = #encodewith
      
      If FindString(GetGadgetText(#pass),"CRF",0) :  SetGadgetText(#Text_33,"Quant") :  DisableGadget(#cds,1) : SetGadgetText(#Text_32,"Quality") : EndIf
      If FindString(GetGadgetText(#pass),"CRF",0)=0 : SetGadgetText(#Text_33,"kbp/s") : DisableGadget(#cds,0) : SetGadgetText(#Text_32,"Video Bitrate") : EndIf
      
    ElseIf GadgetID = #audibit
      Dimb()
      
      
    ElseIf GadgetID = #removequeuejob
      RemoveGadgetItem(#queue,0)
      
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
      
      queuecount.l=0
      queue.l=0
      If GetGadgetText(#pass)="1 pass" : passx.l=1 : audioencoding() : start() :  mux() : startqueue() : EndIf
      If GetGadgetText(#pass)="2 pass"
        audioencoding()
        passx.l=2 : start()
        passx.l=3 : start()
        mux()
        clean()
        startqueue()
      EndIf
      If GetGadgetText(#pass)="CRF 1 pass" : passx.l=4 : audioencoding() : start() : mux() : clean() : startqueue() : EndIf
      If GetGadgetText(#pass)="QP 1 pass" : passx.l=8 : audioencoding() : start()  : mux() : clean() : startqueue() : EndIf
      
      
    ElseIf GadgetID = #addtoqueue
      
      queuecount.l=queuecount.l+1
      queue.l=1
      If GetGadgetText(#pass)="1 pass" : passx.l=1 : audioencoding() : start() : mux() :clean() :  EndIf
      If GetGadgetText(#pass)="2 pass"
        audioencoding()
        passx.l=2 : start()
        passx.l=3 : start()
        mux()
        clean()
      EndIf
      If GetGadgetText(#pass)="CRF 1 pass" : passx.l=4 : audioencoding() : start()  : mux() : clean() : EndIf
      If GetGadgetText(#pass)="QP 1 pass" : passx.l=8 : audioencoding() : start()  : mux() :  clean() : EndIf
      
    ElseIf GadgetID = #startqueue
      startqueue()
      
    ElseIf GadgetID = #paypal
      MessageRequester("Thanks For Your Support!", "Without your donation MultiX264 will be never a better application!", #PB_MessageRequester_Ok )
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
; Executable = MultiX264_x86
; DisableDebugger
; EnableCompileCount = 1574
; EnableBuildCount = 174
; EnableExeConstant
; IDE Options = PureBasic 4.60 Beta 4 (Windows - x86)
; CursorPosition = 1632
; FirstLine = 1618
; Folding = ------
; EnableXP
; EnableUser
; UseIcon = ___logo.ico
; Executable = MultiX264.exe
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 4.60 Beta 4 (Windows - x86)
; EnableCompileCount = 1028
; EnableBuildCount = 1593
; EnableExeConstant