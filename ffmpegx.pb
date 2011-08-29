; PureBasic Visual Designer v3.95 build 1485 (PB4Code)

IncludeFile "ffmpegx_include.pb"

Global inputfile.s,framecount.l,framerate.f,ar.s,twidth.l,mess.s,theight.l,tsec.l,height.l,width.l
Global acbottom.l,acleft.l,acright.l,actop.l,aspectinfo.f,encostring.s
Global messinfo.s,outputinfo.s,here.s,ffmpegbat.s,audioffmpegbat.s,outputfile.s,resizeffmpegbat.s,countprofile.l
Global hour.l, minute.l, second.l,here.s,videocodec.s,queue.l, queuecount.l,passx.l,ffmpeg.s,mplayer.s,x264.s
Global linux,windows

Procedure start()
  
  If outputfile.s="" : outputfile.s="autoffmpeg_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".avi" : EndIf
  
  ffmpegbat.s=""
  
  If windows=#True 
    thread.s=" -threads "+StrF(Val(GetEnvironmentVariable("NUMBER_OF_PROCESSORS"))*1.5,0)+" "
  EndIf
  
 ;  If OSVersion()<=#PB_OS_Linux_Future : thread.s="-threads 0 " : EndIf
  
  If ReadFile(777,here.s+"profile.txt")
    While Eof(777) = #False
      line.s = ReadString(777)
      If FindString(line.s,";"+Str(GetGadgetState(#speedbar))+";",0) And FindString(line.s,GetGadgetText(#presetsummary)+";",0)
        encostring.s=StringField(line.s,4,";")
      EndIf
    Wend
    CloseFile(777)
  EndIf
  
  If GetGadgetText(#presetsummary)="H264 ffpreset"
    
    If ExamineDirectory(0,here+"applications\presets","*.ffpreset")
      countprofile.l=0
      Repeat
        type=NextDirectoryEntry(0)
        If type=1 ; File
          a$=LCase(DirectoryEntryName(0))
          countprofile.l=countprofile.l+1
          If countprofile.l=GetGadgetState(#speedbar)
            encostring.s="-fpre "+Chr(34)+here.s+"applications\presets\"+a$+Chr(34)+" "
          EndIf
        EndIf
      Until type=0
    EndIf
    
  EndIf
  
  encostring.s=ReplaceString(encostring.s,"-threads 0",thread.s)
  
  ffmpegbat.s=ffmpeg.s+" -i "+Chr(34)+inputfile.s+Chr(34)+" "
  
  ffmpegbat.s=ffmpegbat.s+encostring.s+" "
  
  audioffmpegbat.s=""
  resizeffmpegbat.s=""
  
  leftcrop.l=Val(GetGadgetText(#leftcrop))
  topcrop.l=Val(GetGadgetText(#topcrop))
  rightcrop.l=Val(GetGadgetText(#rightcrop))
  bottomcrop.l=Val(GetGadgetText(#bottomcrop))
  width.l=Val(GetGadgetText(#width))
  height.l=Val(GetGadgetText(#height))
  
   If GetGadgetState(#allowresize)=1
    
    If leftcrop.l+topcrop.l+rightcrop.l+bottomcrop.l>0
      resizeffmpegbat.s=" -vf crop="+Str(twidth.l-acleft.l-acright.l)+":"+Str(theight.l-actop.l-acbottom.l)+":"+Str(acright.l)+":"+Str(acbottom.l)
      If width.l+height.l>0
        resizeffmpegbat.s=resizeffmpegbat.s+",scale="+Str(width.l)+":"+Str(height.l)+" "
         resizeffmpegbat.s=resizeffmpegbat.s+"-aspect "+GetGadgetText(#dar)+" "
      EndIf
    EndIf
    
    If leftcrop.l+topcrop.l+rightcrop.l+bottomcrop.l=0
      If width.l+height.l>0
        resizeffmpegbat.s=resizeffmpegbat.s+"-s "+Str(width.l)+"x"+Str(height.l)+" "
      EndIf
    EndIf
    
  EndIf
    
  If GetGadgetState(#deinterlace)=1 : ffmpegbat.s=ffmpegbat.s+"-deinterlace " : EndIf
  
  If GetGadgetText(#framerate)<>"automatic"
    If GetGadgetState(#deinterlace)=0
      ffmpegbat.s=ffmpegbat.s+"-r "+GetGadgetText(#framerate)+" "
    EndIf
  EndIf
  
  If FindString(GetGadgetText(#audiocodec),"MP3",0) : audioffmpegbat.s=audioffmpegbat.s+"-acodec libmp3lame -ab "+GetGadgetText(#audibit)+"k " : EndIf
  If FindString(GetGadgetText(#audiocodec),"AAC",0) : audioffmpegbat.s=audioffmpegbat.s+"-acodec libfaac -ab "+GetGadgetText(#audibit)+"k " : EndIf
  If FindString(GetGadgetText(#audiocodec),"OGG",0) : audioffmpegbat.s=audioffmpegbat.s+"-acodec libvorbis -ab "+GetGadgetText(#audibit)+"k " : EndIf
  If FindString(GetGadgetText(#audiocodec),"FLAC",0) : audioffmpegbat.s=audioffmpegbat.s+"-acodec flac " : EndIf
  If FindString(GetGadgetText(#audiocodec),"COPY",0) : audioffmpegbat.s=audioffmpegbat.s+"-acodec copy " : EndIf
  If FindString(GetGadgetText(#audiocodec),"WMA",0) : audioffmpegbat.s=audioffmpegbat.s+"-acodec wmav2 -ab "+GetGadgetText(#audibit)+"k " : EndIf
  
  If GetGadgetText(#sampling)<>"AUTO" : audioffmpegbat.s=audioffmpegbat.s+"-ar "+GetGadgetText(#sampling)+" " : EndIf
  Select GetGadgetText(#channel)
  Case "1"
    audioffmpegbat.s=audioffmpegbat.s+"-ac 1 "
  Case "2"
    audioffmpegbat.s=audioffmpegbat.s+"-ac 2 "
  EndSelect
  If GetGadgetState(#audionormalize)=1 : audioffmpegbat.s=audioffmpegbat.s+"-vol 256 " : EndIf
  If GetGadgetState(#audiogain)=1 : audioffmpegbat.s=audioffmpegbat.s+"-vol "+GetGadgetText(#audiogain)+" " : EndIf
  If GetGadgetState(#audiotrack)>1
    mess.s=GetGadgetText(#audiotrack)
    aid.s=StringField(mess.s,2,"#")
    aid.s=StringField(aid.s,1,":")
    aid.s=StringField(aid.s,2,".")
    If FindString(aid.s,"[",0) : aid.s=StringField(aid.s,1,"[") : EndIf
    If FindString(aid.s,"(",0) : aid.s=StringField(aid.s,1,"(") : EndIf
    audioffmpegbat.s=audioffmpegbat.s+"-map [0:0] -map ["+aid.s+":0] "
  EndIf
  
  If GetGadgetText(#vframes)<>"" : ffmpegbat.s=ffmpegbat.s+" -vframes "+GetGadgetText(#vframes)+" " : EndIf
  
  If passx.l=1 : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-b "+GetGadgetText(#videokbits)+"k "+audioffmpegbat.s+"-y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
  If passx.l=2 : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-b "+GetGadgetText(#videokbits)+"k "+audioffmpegbat.s+"-y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
  If passx.l=3 : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-pass 1 -b "+GetGadgetText(#videokbits)+"k -an -y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
  If passx.l=4 : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-pass 2 -b "+GetGadgetText(#videokbits)+"k "+audioffmpegbat.s+" -y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
  If passx.l=5
    If FindString(LCase(GetGadgetText(#presetsummary)),"h264",0) : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-crf "+GetGadgetText(#videokbits)+" "+audioffmpegbat.s+" -y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
    If FindString(LCase(GetGadgetText(#presetsummary)),"xvid",0) : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-qscale "+GetGadgetText(#videokbits)+" "+audioffmpegbat.s+" -y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
    If FindString(LCase(GetGadgetText(#presetsummary)),"mpeg4",0) : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-qscale "+GetGadgetText(#videokbits)+" "+audioffmpegbat.s+" -y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
    If FindString(LCase(GetGadgetText(#presetsummary)),"mpeg2",0) : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-qscale "+GetGadgetText(#videokbits)+" "+audioffmpegbat.s+" -y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
    If FindString(LCase(GetGadgetText(#presetsummary)),"wmv",0) : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-qscale "+GetGadgetText(#videokbits)+" "+audioffmpegbat.s+" -y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
  EndIf
  If passx.l=6 : ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-sameq "+audioffmpegbat.s+"-y "+Chr(34)+outputfile.s+Chr(34)   : EndIf
  If passx.l=7
    ffmpegbat.s=ReplaceString(ffmpegbat,encostring.s,"")
    ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+"-vcodec copy "+audioffmpegbat.s+"-y "+Chr(34)+outputfile.s+Chr(34)
  EndIf
  
  ;ffmpeg -i film.vob -an -vcodec rawvideo -pix_fmt yuv420p -cropleft 0 -cropright 0
  
  
  If FindString(LCase(GetGadgetText(#presetsummary)),"pipe",0)
       
    ffmpegbat.s=ffmpeg.s+" -i "+Chr(34)+inputfile.s+Chr(34)+" -an -v 0 -pix_fmt yuv420p -f rawvideo "
    If GetGadgetText(#vframes)<>"" : ffmpegbat.s=ffmpegbat.s+" -vframes "+GetGadgetText(#vframes)+" " : EndIf
    If GetExtensionPart(outputfile.s)="avi" : outputfile.s=ReplaceString(outputfile.s,".avi",".mkv") : EndIf
    ffmpegbat.s=ffmpegbat.s+resizeffmpegbat.s+" -f rawvideo - | "+x264.s+" -o "+Chr(34)+outputfile.s+Chr(34)+" "
    ffmpegbat.s=ffmpegbat.s+encostring.s+" "
    If passx.l=1 : ffmpegbat.s=ffmpegbat.s+"--bitrate "+GetGadgetText(#videokbits)+" ": EndIf
    If passx.l=2 : ffmpegbat.s=ffmpegbat.s+"--bitrate "+GetGadgetText(#videokbits)+" ": EndIf
    If passx.l=3 : ffmpegbat.s=ffmpegbat.s+"--pass 1 --bitrate "+GetGadgetText(#videokbits)+" ": EndIf
    If passx.l=4 : ffmpegbat.s=ffmpegbat.s+"--pass 2 --bitrate "+GetGadgetText(#videokbits)+" ": EndIf
    If passx.l=5 : ffmpegbat.s=ffmpegbat.s+"--crf "+GetGadgetText(#videokbits)+" ": EndIf
    ffmpegbat.s=ffmpegbat.s+"- --input-res "+GetGadgetText(#width)+"x"+GetGadgetText(#height)
   EndIf
  
  
  ffmpegbat.s=ReplaceString(ffmpegbat.s,"  "," ")
  ffmpegbat.s=ReplaceString(ffmpegbat.s,"  "," ")
  
  If queue.l=1
    
    If GetGadgetItemText(#queue,0)<>"prompt $d $t $_$P$G"
      AddGadgetItem(#queue,0,"prompt $d $t $_$P$G" )
    EndIf
    AddGadgetItem(#queue,-1,ffmpegbat.s)
    ProcedureReturn
  EndIf
  
  If passx.l=1 Or passx.l=2 Or passx.l=3 Or passx.l=5 Or passx.l=6 Or passx.l=7
    CreateFile(777,here.s+".autoffmpeg.bat")
  EndIf
  If passx.l=4
    OpenFile(777,here.s+".autoffmpeg.bat")
    FileSeek(777, Lof(777) )
  EndIf
  
  WriteStringN(777,ffmpegbat.s)
  CloseFile(777)
  
  If passx.l=1  Or passx.l=2 Or passx.l=4 Or passx.l=5 Or passx.l=6  Or passx.l=7
    If linux=#True 
      RunProgram("chmod","+x "+Chr(34)+here.s+"autoffmpeg.bat"+Chr(34),here.s,#PB_Program_Wait)
      RunProgram("xterm","-e "+Chr(34)+here.s+"autoffmpeg.bat"+Chr(34),here.s,#PB_Program_Wait)
    EndIf
    If windows=#True    
      RunProgram(here.s+".autoffmpeg.bat","",here.s)
    EndIf
  EndIf
  queue.l=0
  
EndProcedure

Procedure startqueue()
  
  CreateFile(666,here.s+".ffmpegqueue.bat")
  WriteStringN(666,"")
  WriteStringN(666,GetGadgetText(#queue))
  CloseFile(666)
  If linux=#True 
    RunProgram("chmod","+x "+Chr(34)+here.s+".ffmpegqueue.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+".ffmpegqueue.bat"+Chr(34),here.s)
  EndIf
  If windows=#True
    RunProgram(here.s+".ffmpegqueue.bat","",here.s)
  EndIf
  
EndProcedure


Procedure parseprofile_base()
  
  ClearGadgetItems(#presetsummary)
  Dim codec.s(1000)
  a.l=0
  b.l=0
  
  If ReadFile(888,here.s+"profile.txt")<>0
    While Eof(888) = #False
      line.s = ReadString(888)
      a.l=Val(StringField(line.s,2,";"))
      b.l=b.l+1
      codec.s(b.l)=StringField(line.s,1,";")
    Wend
    CloseFile(888)
  EndIf
  
  
  For aa=1 To 1000
    If codec.s(aa)=codec.s(aa-1) : codec.s(aa-1)="" : EndIf
  Next aa
  
  For b=0 To 1000
    If Len(codec.s(b))>2 : AddGadgetItem(#presetsummary,-1,codec.s(b))  : EndIf
  Next
  
  
  If ExamineDirectory(0,here+"applications\presets","*.ffpreset")
    countprofile.l=0
    Repeat
      type=NextDirectoryEntry(0)
      If type=1 ; File
        a$=LCase(DirectoryEntryName(0))
        countprofile.l=countprofile.l+1
      EndIf
    Until type=0
    If countprofile.l > 1 : AddGadgetItem(#presetsummary,-1,"H264 ffpreset") : EndIf
  EndIf
  
  
EndProcedure

Procedure parseprofile()
  
  countprofile.l=0
  
  If GetGadgetText(#presetsummary)<>"H264 ffpreset"
    
    If ReadFile(888,here.s+"profile.txt")
      While Eof(888) = 0
        line.s = LCase(ReadString(888))
        If FindString(line.s,LCase(GetGadgetText(#presetsummary))+";",0)
          countprofile.l=countprofile.l+1
        EndIf
      Wend
      CloseFile(888)
    EndIf
    SetGadgetAttribute(#speedbar, #PB_TrackBar_Maximum ,countprofile.l)
    
    
    
    If ReadFile(888,here.s+"profile.txt")
      While Eof(888) = 0
        line.s = ReadString(888)
        If FindString(line.s,";"+Str(GetGadgetState(#speedbar))+";",0) And FindString(line.s,GetGadgetText(#presetsummary),0)
          SetGadgetText(#speedqualitytext,GetGadgetText(#presetsummary)+": "+StringField(line,3,";"))
        EndIf
      Wend
      CloseFile(888)
    EndIf
    
  EndIf
  
  If GetGadgetText(#presetsummary)="H264 ffpreset"
    
    If ExamineDirectory(0,here+"applications\presets","*.ffpreset")
      Repeat
        type=NextDirectoryEntry(0)
        If type=1 ; File
          a$=LCase(DirectoryEntryName(0))
          countprofile.l=countprofile.l+1
        EndIf
      Until type=0
      SetGadgetAttribute(#speedbar, #PB_TrackBar_Maximum ,countprofile.l)
    EndIf
    
    
    If ExamineDirectory(0,here+"applications\presets","*.ffpreset")
      countprofile.l=0
      Repeat
        type=NextDirectoryEntry(0)
        If type=1 ; File
          a$=LCase(DirectoryEntryName(0))
          countprofile.l=countprofile.l+1
          If countprofile.l=GetGadgetState(#speedbar)
            SetGadgetText(#speedqualitytext,a$)
          EndIf
        EndIf
      Until type=0
    EndIf
    
    
  EndIf
  
  
EndProcedure



Procedure Dimb()
  
  Dimb.f=Val(GetGadgetText(#cds))*1024*1024
  
  bitrate.f=(Dimb.f-framecount.l*24-(Val(GetGadgetText(#audibit))*1024*(framecount.l/framerate.f)*0.128))/((framecount.l/framerate.f)*0.128/1000)/1000/1000
  
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
  
  SetGadgetText(#videokbits,StrF(bitrate.f,0))
  
EndProcedure

Procedure preview()
  
  mess.s=""
  If GetExtensionPart(inputfile.s)="dvr-ms" : mess4.s=" -demuxer 35 " : EndIf
  vcrop.s="crop="+Str(twidth.l-Val(GetGadgetText(#leftcrop))-Val(GetGadgetText(#rightcrop)))+":"+Str(theight.l-Val(GetGadgetText(#topcrop))-Val(GetGadgetText(#bottomcrop)))+":"+GetGadgetText(#leftcrop)+":"+GetGadgetText(#topcrop)
  RunProgram(mplayer.s," -vf "+vcrop.s+",scale="+GetGadgetText(#width)+":"+GetGadgetText(#height)+" -aspect "+GetGadgetText(#arcombo)+" "+Chr(34)+inputfile.s+Chr(34),here.s)
  
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


Procedure checkmedia2()
 
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
  
  DeleteFile(here.s+"ffmpeganalysis.bat")
  DeleteFile(here.s+"ffmpeganalysis.txt")
  CreateFile(987,here.s+"ffmpeganalysis.bat")
  
  If linux=#True 
    WriteString(987,ffmpeg.s+" -i "+Chr(34)+checkfile.s+Chr(34)+" -vf select='not(mod(n\,100))',cropdetect -an -y deleteme.avi 2>ffmpeganalysis.txt")
  EndIf
  If windows=#True 
    WriteString(987,ffmpeg.s+" -i "+Chr(34)+checkfile.s+Chr(34)+" -vf select=not(mod(n\,100)),cropdetect -an -y deleteme.avi 2>ffmpeganalysis.txt")
  EndIf
  
  CloseFile(987)
  
    If windows=#True 
    RunProgram(here.s+"ffmpeganalysis.bat","",here.s,#PB_Program_Wait)
  EndIf
 If linux=#True 
    RunProgram("chmod","+x "+Chr(34)+here.s+"ffmpeganalysis.bat"+Chr(34),here.s,#PB_Program_Wait)
    RunProgram("xterm","-e "+Chr(34)+here.s+"ffmpeganalysis.bat"+Chr(34),here.s,#PB_Program_Wait)
  EndIf
  
  Delay(500)
  
  fh=ReadFile(#PB_Any,here.s+"ffmpeganalysis.txt")
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
    If result=#PB_MessageRequester_Yes : SetGadgetState(#deinterlace,1) : EndIf
  EndIf
  
  dimb()
  
  silentresize()
  
EndProcedure

Procedure autocrop()
  
  
  If windows=#True 
    If FileSize(mplayer.s)=-1
      MessageRequester("AutoFFmpegGui","No mplayer found"+Chr(13)+Chr(13)+"Please download mplayer.exe and put in the same directory as AutoFFmpegGui")
      ProcedureReturn
    EndIf
  EndIf
  
  acbottom.l=0
  acleft.l=0
  cropright.l=0
  actop.l=0
  mess.s=""
  mess1.s=""
  vcrop.s=""
  
  If demuxer35.s="1" :  mess4.s=" -demuxer 35 " : EndIf
  If GetExtensionPart(inputfile.s)="dvr-ms" : mess4.s=" -demuxer 35 " : EndIf
  
  If tsec.l<=120 : ss.s="" :  EndIf
  If tsec.l>120 :  ss.s="-sstep "+StrF(tsec.l/10,0)+" " : EndIf
  
  waitcrop=RunProgram(mplayer.s,mess4.s+"-benchmark -vf cropdetect -nosound -vo null -frames 300 "+ss.s+Chr(34)+inputfile.s+Chr(34),here.s,#PB_Program_Open|#PB_Program_Read)
  
  While ProgramRunning(waitcrop)
    mess.s=ReadProgramString(waitcrop)
    If FindString(mess.s,"-vf crop=",0)
      mess1.s=StringField(mess.s,1,")")
      vcrop.s=Mid(StringField(mess1.s,2,"("),10,1000)
      vcrop1.s=vcrop.s
    EndIf
    
  Wend
  WaitProgram(waitcrop)
  CloseProgram(waitcrop)
  Debug(vcrop.s)
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
  
  SetGadgetText(#bottomcrop,Str(acbottom.l))
  SetGadgetText(#leftcrop,Str(acleft.l))
  SetGadgetText(#rightcrop,Str(acright.l))
  SetGadgetText(#topcrop,Str(actop.l))
  
  If actop.l>100 Or acbottom.l>100 Or acleft.l>100 Or acright.l>100
    MessageRequester("AutoCrop", "Please, check autocrop value", #PB_MessageRequester_Ok )
  EndIf
  
  silentresize()
  
EndProcedure


Procedure openinputfile()
  
  
  If linux=#True 
    inputfile.s=OpenFileRequester("Open File to Encode", last.s, "Supported Movie File|*VOB;*.EVO;*.M2TS;*.TS;*.MTS;*.MKV;.OGM;*.MPG;*.MPEG;*.AVS;*.AVI;*.M2T;*.VRO;*.MOV;*vob;*.evo;*.m2ts;*.ts;*.mts;*.mkv;.ogm;*.mpg;*.mpeg;*.svi;*.m2t;*.vro;*.mov|All files|*.*",0)
  EndIf
  If windows=#True
    inputfile.s=OpenFileRequester("Open File to Encode", last.s, "Supported Movie File|*VOB;*.EVO;*.M2TS;*.TS;*.MTS;*.MKV;.OGM;*.MPG;*.MPEG;*.AVS;*.AVI;*.M2T;*.VRO;*.D2V;*.DGA;*.AVS;*.GRF;*.MOV|All files|*.*",0)
  EndIf
  
  
  If inputfile.s<>""
    SetGadgetText(#inputstring,inputfile.s)
    framecount.l=0
    framerate.f=0
    StatusBarText(#StatusBar_0, 0,"")
    
    If GetGadgetText(#outputstring)=""
      If FindString(LCase(GetGadgetText(#presetsummary)),"264",0) : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"autoffmpeg_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mkv") : EndIf
      If FindString(LCase(GetGadgetText(#presetsummary)),"mpeg4",0) : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"autoffmpeg_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".avi") : EndIf
      If FindString(LCase(GetGadgetText(#presetsummary)),"xvid",0) : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"autoffmpeg_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".avi") : EndIf
      If FindString(LCase(GetGadgetText(#presetsummary)),"wmv",0) : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"autoffmpeg_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".wmv") : EndIf
      If FindString(LCase(GetGadgetText(#presetsummary)),"mpeg2",0) : SetGadgetText(#outputstring,GetPathPart(inputfile.s)+"autoffmpeg_"+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile)))+".mpg") : EndIf
      outputfile.s=GetGadgetText(#outputstring)
    EndIf
    
    
    exts.s=LCase(GetExtensionPart(inputfile.s))
    checkmedia2()
    SetGadgetState(#trackwidth,87)
    silentresize()
  EndIf
  
EndProcedure

Procedure allowresize()
  
     
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


Open_Window_0()
here.s=GetCurrentDirectory()

CompilerIf #PB_Compiler_OS = #PB_OS_Linux : linux=#True : CompilerEndIf
CompilerIf #PB_Compiler_OS = #PB_OS_Windows : windows=#True : CompilerEndIf

If linux=#True : mplayer.s="mplayer" : ffmpeg.s="ffmpeg" :  x264.s="x264" :  EndIf
 
  
If windows=#True
  
  If FileSize(here.s+"x264.exe")<>-1 : x264.s=Chr(34)+here.s+"x264.exe"+Chr(34) : EndIf
  If FileSize(here.s+"mplayer.exe")<>-1 : mplayer.s=Chr(34)+here.s+"mplayer.exe"+Chr(34) : EndIf
  If FileSize(here.s+"ffmpeg.exe")<>-1 : ffmpeg.s=Chr(34)+here.s+"ffmpeg.exe"+Chr(34) : EndIf

  If FileSize(here.s+"applications\mplayer\mplayer.exe")<>-1 : mplayer.s=Chr(34)+here.s+"applications\mplayer\mplayer.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\ffmpeg\ffmpeg.exe")<>-1 : ffmpeg.s=Chr(34)+here.s+"applications\ffmpeg\ffmpeg.exe"+Chr(34) : EndIf
  If FileSize(here.s+"applications\x264\x264.exe")<>-1 : x264.s=Chr(34)+here.s+"applications\x264\x264.exe"+Chr(34) : EndIf
  
  ; path using megui folders ->
  
  If FileSize(here.s+"tools\mencoder\mplayer.exe")<>-1 : mplayer.s=Chr(34)+here.s+"tools\mencoder\mplayer.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\ffmpeg\ffmpeg.exe")<>-1 : ffmpeg.s=Chr(34)+here.s+"tools\ffmpeg\ffmpeg.exe"+Chr(34) : EndIf
  If FileSize(here.s+"tools\x264\x264.exe")<>-1 : x264.s=Chr(34)+here.s+"tools\x264tools.exe"+Chr(34) : EndIf
  
EndIf  
  


parseprofile_base()
SetGadgetState(#presetsummary,0)
parseprofile()


DeleteFile(here.s+"ffmpeganalysis.bat")
DeleteFile(here.s+"autoffmpeg.avs")
DeleteFile(here.s+"autoffmpeg.bat")
DeleteFile(here.s+"ffmpeganalysis.txt")


Repeat ; Start of the event loop
  
  Event = WaitWindowEvent() ; This line waits until an event is received from Windows
  
  WindowID = EventWindow() ; The Window where the event is generated, can be used in the gadget procedures
  
  GadgetID = EventGadget() ; Is it a gadget event?
  
  EventType = EventType() ; The event type
  
  ;You can place code here, and use the result as parameters for the procedures
  
  If Event = #PB_Event_Gadget
    
    If GadgetID = #open
      openinputfile()
      
    ElseIf GadgetID = #save      
      mess.s=GetCurrentDirectory()
      If inputfile.s<>"" : mess.s=GetPathPart(inputfile.s) : EndIf
      outputfile.s=SaveFileRequester("Save output file",GetPathPart(inputfile.s)+Mid(GetFilePart(inputfile.s),0,Len(GetFilePart(inputfile.s))-1-Len(GetExtensionPart(inputfile.s)))+"_autoff","*.avi|*.avi*.mkv|*.mkv|*.mp4|*.mp4|*.h264|*.h264",0)
      index=SelectedFilePattern()
      If outputfile.s<>""
        If index=0 : outputfile.s=outputfile.s+".avi" : EndIf
        If index=1 : outputfile.s=outputfile.s+".mkv" : EndIf
        If index=2 : outputfile.s=outputfile.s+".mp4" : EndIf
        If index=4 : outputfile.s=outputfile.s+".h264" : EndIf
        SetGadgetText(#outputstring,outputfile.s)
      EndIf
            
      
    ElseIf GadgetID = #preview
      preview()
      
    ElseIf GadgetID = #play
      RunProgram(mplayer.s,Chr(34)+inputfile.s+Chr(34),here.s)
      
    ElseIf GadgetID = #cds
      Dimb()
      
    ElseIf GadgetID = #presetsummary
      parseprofile()
      
      
      Select GetGadgetText(#presetsummary)
      Case "pipe to X264","H264 ffpreset"
        ClearGadgetItems(#pass)
        AddGadgetItem(#pass,-1,"1 pass")
        AddGadgetItem(#pass,-1,"2 pass")
        AddGadgetItem(#pass,-1,"CRF 1 pass")
        SetGadgetState(#pass,0)
      Case "WMV"
        ClearGadgetItems(#pass)
        AddGadgetItem(#pass,-1,"1 pass")
        AddGadgetItem(#pass,-1,"2 pass")
        SetGadgetState(#pass,0)
      Default
        ClearGadgetItems(#pass)
        AddGadgetItem(#pass,-1,"1 pass")
        AddGadgetItem(#pass,-1,"2 pass")
        AddGadgetItem(#pass,-1,"CRF 1 pass")
        AddGadgetItem(#pass,-1,"SameQ")
        AddGadgetItem(#pass,-1,"Copy Video")
        SetGadgetState(#pass,0)
      EndSelect
      
    ElseIf GadgetID = #speedbar
      parseprofile()
      
    ElseIf GadgetID = #removequeuejob
      RemoveGadgetItem(#queue,GetGadgetState(#queue))
      
    ElseIf GadgetID = #trackwidth
      silentresize()
      
    ElseIf GadgetID = #height
      silentscale()
      
    ElseIf GadgetID = #width
      silentscale()
      
      ElseIf GadgetID = #allowresize
      allowresize()
      
    ElseIf GadgetID = #modheight
      silentscale()
    ElseIf GadgetID = #modwidth
      silentscale()
      
    ElseIf GadgetID = #topcrop
      silentscale()
      
    ElseIf GadgetID = #itu
      silentscale()
      
    ElseIf GadgetID = #anamorphic
      silentscale()
      
    ElseIf GadgetID = #bottomcrop
      silentscale()
      
    ElseIf GadgetID = #rightcrop
      silentscale()
      
    ElseIf GadgetID = #leftcrop
      silentscale()
      
    ElseIf GadgetID = #arcombo
      silentscale()
      
    ElseIf GadgetID = #buttonaddtoqueue
      AddGadgetItem(#queue,-1,GetGadgetText(#addedtoqueue))
      
    ElseIf GadgetID = #autocrop
      autocrop()
      
    ElseIf GadgetID = #encode
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
      
      If GetGadgetText(#pass)="SameQ"
        passx.l=6
        start()
      EndIf
      
      If GetGadgetText(#pass)="Copy Video"
        passx.l=7
        start()
      EndIf
      
    ElseIf GadgetID = #addtoqueue
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
      
      If GetGadgetText(#pass)="SameQ"
        passx.l=6
        start()
      EndIf
      
      If GetGadgetText(#pass)="Copy Video"
        passx.l=7
        start()
      EndIf
      
    ElseIf GadgetID = #pass
      Select GetGadgetText(#pass)
      Case "Copy Video"
        DisableGadget(#presetsummary,1)
        DisableGadget(#cds,1)
        DisableGadget(#videokbits,1)
      Case "CRF 1 pass"
        DisableGadget(#cds,1)
        SetGadgetText(#Text_33,"Quant")
        SetGadgetText(#Text_32,"Quality")
      Case "SameQ"
        DisableGadget(#videokbits,1)
        DisableGadget(#cds,1)
        SetGadgetText(#Text_33,"Quant")
        SetGadgetText(#Text_32,"Quality")
      Default
        DisableGadget(#cds,0)
        DisableGadget(#videokbits,0)
        DisableGadget(#presetsummary,0)
        SetGadgetText(#Text_33,"kbp/s")
        SetGadgetText(#Text_32,"Video Bitrate")
      EndSelect
      
      
    ElseIf GadgetID = #startqueue
      startqueue()
      
    ElseIf GadgetID = #paypal
      MessageRequester("Thanks For Your Support!", "Without your donation AutoFFmpegGui will be never a better application!", #PB_MessageRequester_Ok )
      RunProgram("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4278562","","")
      
    ElseIf GadgetID = #fixbutton
      filetofix.s=OpenFileRequester("Open file AVI to fix","*.*","*.avi|*.avi",0)
      If filetofix.s<>""  : SetGadgetText(#filetofix,filetofix.s) : EndIf
      
    ElseIf GadgetID = #outputbuttonfix
      filefixed.s=SaveFileRequester("Save file AVI fixed","*.*","*.avi|*.avi",0)
      If GetExtensionPart(filefixed.s)="" : filefixed.s=filefixed.s+".avi" : EndIf
      If filefixed.s<>"" : SetGadgetText(#filefixed,filefixed.s) : EndIf
      
    ElseIf GadgetID = #startfix
      RunProgram(ffmpeg.s," -i "+Chr(34)+GetGadgetText(#filetofix)+Chr(34)+" -acodec copy -vcodec copy "+Chr(34)+GetGadgetText(#filefixed)+Chr(34),here.s)
      
      
    EndIf
    
  EndIf
  
Until Event = #PB_Event_CloseWindow ; End of the event loop

End
;
; IDE Options = PureBasic 4.60 Beta 4 (Windows - x86)
; CursorPosition = 474
; FirstLine = 457
; Folding = ---
; EnableXP
; EnableUser
; UseIcon = ___logo.ico
; Executable = AutoFFmpegGui.exe
; DisableDebugger
; CompileSourceDirectory
; EnableCompileCount = 599
; EnableBuildCount = 31
; EnableExeConstant