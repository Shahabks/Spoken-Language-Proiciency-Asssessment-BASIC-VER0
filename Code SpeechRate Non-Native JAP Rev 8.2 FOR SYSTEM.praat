###########################################################################
#                                                                         #
#  Praat Script Spoken Communication Proficiency Test                     #
#  Copyright (C) 2017  Shahab Sabahi                                      #
#                                                                         #
#                                                                             #
#                                                                         #
###########################################################################


form Counting Syllables in Sound Utterances
   real Silence_threshold_(dB) -20
   real Minimum_dip_between_peaks_(dB) 2
   real Minimum_pause_duration_(s) 0.3
   boolean Keep_Soundfiles_and_Textgrids yes
   sentence directory C:\Users\Sabahi.s\Desktop\MYSOL Scoring File\INPUT/
endform

# shorten variables
silencedb = 'silence_threshold'
mindip = 'minimum_dip_between_peaks'
showtext = 'keep_Soundfiles_and_Textgrids'
minpause = 'minimum_pause_duration'
 
# read files
Create Strings as file list... list 'directory$'/*.wav
numberOfFiles = Get number of strings
for ifile to numberOfFiles
   select Strings list
   fileName$ = Get string... ifile
   Read from file... 'directory$'/'fileName$'

# use object ID
   soundname$ = selected$("Sound")
   soundid = selected("Sound")
   
   originaldur = Get total duration
   # allow non-zero starting time
   bt = Get starting time

   # Use intensity to get threshold
   To Intensity... 50 0 yes
   intid = selected("Intensity")
   start = Get time from frame number... 1
   nframes = Get number of frames
   end = Get time from frame number... 'nframes'

   # estimate noise floor
   minint = Get minimum... 0 0 Parabolic
   # estimate noise max
   maxint = Get maximum... 0 0 Parabolic
   #get .99 quantile to get maximum (without influence of non-speech sound bursts)
   max99int = Get quantile... 0 0 0.99

   # estimate Intensity threshold
   threshold = max99int + silencedb
   threshold2 = maxint - max99int
   threshold3 = silencedb - threshold2
   if threshold < minint
       threshold = minint
   endif

  # get pauses (silences) and speakingtime
   To TextGrid (silences)... threshold3 minpause 0.1 silent sounding
   textgridid = selected("TextGrid")
   silencetierid = Extract tier... 1
   silencetableid = Down to TableOfReal... sounding
   nsounding = Get number of rows
   npauses = 'nsounding'
   speakingtot = 0
   for ipause from 1 to npauses
      beginsound = Get value... 'ipause' 1
      endsound = Get value... 'ipause' 2
      speakingdur = 'endsound' - 'beginsound'
      speakingtot = 'speakingdur' + 'speakingtot'
   endfor

   select 'intid'
   Down to Matrix
   matid = selected("Matrix")
   # Convert intensity to sound
   To Sound (slice)... 1
   sndintid = selected("Sound")

   # use total duration, not end time, to find out duration of intdur
   # in order to allow nonzero starting times.
   intdur = Get total duration
   intmax = Get maximum... 0 0 Parabolic

   # estimate peak positions (all peaks)
   To PointProcess (extrema)... Left yes no Sinc70
   ppid = selected("PointProcess")

   numpeaks = Get number of points

   # fill array with time points
   for i from 1 to numpeaks
       t'i' = Get time from index... 'i'
   endfor 


   # fill array with intensity values
   select 'sndintid'
   peakcount = 0
   for i from 1 to numpeaks
       value = Get value at time... t'i' Cubic
       if value > threshold
             peakcount += 1
             int'peakcount' = value
             timepeaks'peakcount' = t'i'
       endif
   endfor


   # fill array with valid peaks: only intensity values if preceding 
   # dip in intensity is greater than mindip
   select 'intid'
   validpeakcount = 0
   currenttime = timepeaks1
   currentint = int1

   for p to peakcount-1
      following = p + 1
      followingtime = timepeaks'following'
      dip = Get minimum... 'currenttime' 'followingtime' None
      diffint = abs(currentint - dip)

      if diffint > mindip
         validpeakcount += 1
         validtime'validpeakcount' = timepeaks'p'
      endif
         currenttime = timepeaks'following'
         currentint = Get value at time... timepeaks'following' Cubic
   endfor


   # Look for only voiced parts
   select 'soundid' 
   To Pitch (ac)... 0.02 30 4 no 0.03 0.25 0.01 0.35 0.25 450
   # keep track of id of Pitch
   pitchid = selected("Pitch")

   voicedcount = 0
   for i from 1 to validpeakcount
      querytime = validtime'i'

      select 'textgridid'
      whichinterval = Get interval at time... 1 'querytime'
      whichlabel$ = Get label of interval... 1 'whichinterval'

      select 'pitchid'
      value = Get value at time... 'querytime' Hertz Linear

      if value <> undefined
         if whichlabel$ = "sounding"
             voicedcount = voicedcount + 1
             voicedpeak'voicedcount' = validtime'i'
         endif
      endif
   endfor

   
   # calculate time correction due to shift in time for Sound object versus
   # intensity object
   timecorrection = originaldur/intdur

   # Insert voiced peaks in TextGrid
   if showtext > 0
      select 'textgridid'
      Insert point tier... 1 syllables
      
      for i from 1 to voicedcount
          position = voicedpeak'i' * timecorrection
          Insert point... 1 position 'i'
      endfor
   endif

Save as text file: "C:\Users\Sabahi.s\Desktop\MYSOL Scoring File\INPUT/'soundname$'.TextGrid"

   # clean up before next sound file is opened
    select 'intid'
    plus 'matid'
    plus 'sndintid'
    plus 'ppid'
    plus 'pitchid'
    plus 'silencetierid'
    plus 'silencetableid'

	Read from file... 'directory$'/'fileName$'
	soundname$ = selected$ ("Sound")
	To Formant (burg)... 0 5 5500 0.025 50
	Read from file... 'directory$'/'soundname$'.TextGrid
	int=Get number of intervals... 2


# We then calculate F1, F2 and F3

fff= 0
eee= 0
inside= 0
outside= 0
for k from 2 to 'int'
	select TextGrid 'soundname$'
	label$ = Get label of interval... 2 'k'
	if label$ <> ""

	# calculates the onset and offset
 		vowel_onset = Get starting point... 2 'k'
  		vowel_offset = Get end point... 2 'k'

		select Formant 'soundname$'
		f_one = Get mean... 1 vowel_onset vowel_offset Hertz
		f_two = Get mean... 2 vowel_onset vowel_offset Hertz
		f_three = Get mean... 3 vowel_onset vowel_offset Hertz
		
		ff = 'f_two'/'f_one'
		lnf1 = 'f_one'
		lnf2f1 = ('f_two'/'f_one')
		uplim =(-0.012*'lnf1')+13.17
		lowlim =(-0.0148*'lnf1')+8.18
	
		f1uplim =(lnf2f1-13.17)/-0.012
		f1lowlim =(lnf2f1-8.18)/-0.0148
	
	
	
	if lnf1>='f1lowlim' and lnf1<='f1uplim' 
	    inside = 'inside'+1
		else
		   outside = 'outside'+1
	endif
		fff = 'fff'+'f1uplim'
		eee = 'eee'+'f1lowlim'
ffff = 'fff'/'int'
eeee = 'eee'/'int'
pron =('inside'*100)/('inside'+'outside')
prom =('outside'*100)/('inside'+'outside')
prob1 = invBinomialP ('pron'/100, 'inside', 'inside'+'outside')
prob = 'prob1:2'
		
	endif
endfor

lnf0 = (ln(f_one)-5.65)/0.31
f00 = exp (lnf0)

    Remove
    if showtext < 1
       select 'soundid'
       plus 'textgridid'
       Remove
    endif

# summarize results in Info window
   speakingrate = 'voicedcount'/'originaldur'
   speakingraterp = ('voicedcount'/'originaldur')*100/3.93
   articulationrate = 'voicedcount'/'speakingtot'
   articulationraterp = ('voicedcount'/'speakingtot')*100/4.64
   npause = 'npauses'-1
   asd = 'speakingtot'/'voicedcount'
   avenumberofwords = ('voicedcount'/1.74)/'speakingtot'
   avenumberofwordsrp = (('voicedcount'/1.74)/'speakingtot')*100/2.66
   nuofwrdsinchunk = (('voicedcount'/1.74)/'speakingtot')* 'speakingtot'/'npauses'
   nuofwrdsinchunkrp = ((('voicedcount'/1.74)/'speakingtot')* 'speakingtot'/'npauses')*100/9
   avepauseduratin = ('originaldur'-'speakingtot')/('npauses'-1)
   avepauseduratinrp = (('originaldur'-'speakingtot')/('npauses'-1))*100/0.75
   balance = ('voicedcount'/'originaldur')/('voicedcount'/'speakingtot')
   balancerp = (('voicedcount'/'originaldur')/('voicedcount'/'speakingtot'))*100/0.85
   nuofwrds= ('voicedcount'/1.74)
   f1norm = -0.0118*'pron'*'pron'+0.5072*'pron'+394.34
   inpro = ('nuofwrds'*60/'originaldur')
   polish = 'originaldur'/2



  if f00<90 or f00>255
         z$="Your intonation does not sound much natural; it seems you read a transcript or speak flat. You need to consider fall and rise in your tone in sentences as well as the stressed and weak sounds in words; for example, in the order GO TO BED GO and BED are stressed and TO is not; and the second syllable of BANANA is stressed and the first and third are weak. Work on the features of connected speech and emphasizing, things that happen when you connect sounds together or put much emphasis on particular words. For example, connected speech produces contractions such as doesn’t, linking sounds such as the (j) in I AM, lost sounds such as the (t) in I DO NOT KNOW, and changed sounds such as the (t) in WHITE BAG changing to a (p)." 
               elsif f00<97 or f00>245  
                     z$="Your speech has some inappropriate intonation when you must create language. For example, you need to consider fall and rise in your tone as well as the stressed and weak words in speech; for example, in the order GO TO BED GO and BED are stressed and TO is not. Also work on the features of connected speech and emphasizing, things that happen when you connect sounds together or put emphasis on particular words. For example, connected speech produces contractions such as doesn’t, linking sounds such as the (j) in I AM, lost sounds such as the (t) in I DO NOT KNOW, and changed sounds such as the (t) in WHITE BAG changing to a (p)."
                           elsif f00<115 or f00>245 
                                       z$="Your intonation and stress are generally accurate and highly intelligible. Work on the features of connected speech and emphasizing, things that happen when you connect sounds together or put much emphasis on particular words. For example, connected speech produces contractions such as doesn’t, linking sounds such as the (j) in I AM, lost sounds such as the (t) in I DO NOT KNOW, and changed sounds such as the (t) in WHITE BAG changing to a (p)."
						elsif f00<=245 and f00>=115 
						z$="Native-like. It indicates that your intonation and stress are at all times highly intelligible."
						else 
                         z$= "Flat tone OR unclear sound."                        
    endif
    if nuofwrdsinchunk>=6.24 and avepauseduratin<=1.0 
         l$="Excellent. You consistently maintain a high degree of basic and complex grammatical accuracy."
		elsif nuofwrdsinchunk>=6.24 and avepauseduratin>1.0 
            l$="Effective. You maintain a good degree of basic and complex grammatical accuracy. Most likely you correctly use idiomatic expressions and collocations."
          elsif nuofwrdsinchunk>=4.4 and nuofwrdsinchunk<=6.24 and avepauseduratin<=1.15 
            l$="Good. You use basic and complex grammar with minor grammatical mistakes when using complex grammatical structures. You need to use more complex structures such as relative clauses and conditional tenses."
		elsif nuofwrdsinchunk>=4.4 and nuofwrdsinchunk<=6.24 and avepauseduratin>1.15 
            l$="Satisfactory. Your speech has some grammatical mistakes when using complex grammatical structures. You need to use complex structures such as those which have a main clause and one or more adverbial clauses and also conditional tenses. Adverbial clauses usually come after the main clause, for example; Her brother got married (main) when she was very young (adv.) or Although (conj) a few snakes are dangerous (adv) most of them are quite harmless (main)."
              elsif nuofwrdsinchunk<4.4 and avepauseduratin<=1.15 
                 l$="Your speech has a few grammatical mistakes when using complex grammatical structures. You might use more simple sentences (one clause) than complex sentences. You need to use correctly relative clauses, conditional tenses, Comparative/superlative sentences."
                   elsif nuofwrdsinchunk<=4.4 and avepauseduratin>1.15 
                     l$="You have limited grammatical knowledge. You need to use correctly simple sentences (one clause) and some complex sentences. You need to use relative clauses, conditional tenses, Comparative/superlative sentences. (Complex structures such as those which have a main clause and one or more adverbial clauses and also conditional tenses. Adverbial clauses usually come after the main clause, for example; Her brother got married (main) when she was very young (adv.) or Although (conj) a few snakes are dangerous (adv) most of them are quite harmless (main))"
                       else
                         l$="Unclear Sound."
    endif 
	if balance>=0.69 and avenumberofwords>=2.60  
           o$="Your speech reflects an excellent pragmatic language appropriateness. has a very good command of professional vocabulary in the question context, presents sophisticated arguing an opinion."
		elsif balance>=0.60 and avenumberofwords>=2.43  
           o$="Your speech reflects a good thought organization and pragmatic language appropriateness, has a good command of professional vocabulary in the question context, presents successfully a formal discussion."
             elsif balance>=0.5 and avenumberofwords>=2.25 
               o$="Your speech reflects a fair thought organization, has an adequate professional vocabulary in the question context, presents a fair pragmatic language appropriateness. You need to use communication strategies effectively when unsure about the topic."
                  elsif balance>=0.5 and avenumberofwords>=2.07 
                       o$="Your speech reflects problems with thought organization, has limited professional vocabulary in the question context, has some difficulty keeping up with the arguing an opinion. You need to expand your vocabulary and structures knowledge and use communication strategies effectively when unsure about the topic."
                          elsif balance>=0.5 and avenumberofwords>=1.95 
                            o$="Your speech reflects lack of vocabulary knowledge and unfamiliarity with communication strategies and speaking patterns or unfamiliarity with the topic of the question."
                               else 
                                o$= "Unclear Sound." 
    endif
     if speakingrate<=4.26 and speakingrate>=3.16 
           q$="You are highly confident about using language for a large diversity of topics. You express opinions fluently and spontaneously almost effortlessly. You might have problems when you produce speech for a conceptually difficult topic."
		elsif speakingrate<=3.16 and speakingrate>=2.54 
           q$="You are confident about using language for adequately a large diversity of topics. You are fluent and spontaneous but occasionally need to search for expressions or compromise on saying exactly what you wish to say . You might have problems when you produce speech for a conceptually difficult topic."    
             elsif speakingrate<=2.54 and speakingrate>=1.91 
               q$="You can produce stretches of the language use but only for range of familiar topics. You are hesitant to speak your ideas when you search for expressions, so there are few noticeably long pauses in your speech."     
                 elsif speakingrate<=1.91 and speakingrate>=1.28 
                     q$="Your speech generally comprehensible though is fairly slow because of pronunciation or intonation limitations AND/OR you are fairly confident about using language as you search for expressions and vocabulary, and less confident when you structure your sentences in your mind, so there are many noticeably long pauses in your speech."     
                       elsif speakingrate<=1.28 and speakingrate>=1.0 
                         q$="Your speech is broken, has only short sentences, and you are not confident about using language, there are many pauses because of hesitation to speak your ideas when you search for expressions, vocabulary and grammatical structures, AND/OR pronunciation or intonation limitations."          
                           else 
                             q$="Disfluency, Cluttering, Your speech is either slow or too fast, and inaccurate "        
    endif    
      if balance>=0.69 and articulationrate>=4.54 
           w$="You present ideas articulately and persuasively in a complex discussion. Your speech has sophisticated arguing pattern, has no difficulty in using idiomatic and professional language, it indicates that you are familiar with the topic and using language well"
		elsif balance>=0.60 and articulationrate>=4.22 
           w$="You successfully present and justify ideas in a formal discussion manner, you use arguing principles effectively, it indicates that you know the topic and use language well."
             elsif balance>=0.50 and articulationrate>=3.91 
               w$="You deliver ideas and opinions though not effectively. It is occasionally hard to comprehend what you mean. There are occasionally some thoughts-speech weaknesses when you express your thoughts with words. It is because of (either) inadequate knowledge of professional vocabulary, (AND/OR) organizing ideas in mind (unfamiliarity with communication strategies) , (AND/OR) unable to use effectively the discussion principles."
                 elsif balance>=0.5 and articulationrate>=3.59 
                     w$="Your speech is not articulated well. It is sometimes hard to comprehend what you mean. It suggests that your speech has structural weaknesses such as lack of categorizing and comparing ideas, unable to use standard expressions, unable to organize thoughts, or unfamiliarity with the topic and unable to use the logical structure."
                       elsif balance>=0.5 and articulationrate>=3.10 
                         w$="You have very limited vocabulary knowledge, very limited comprehension ability, unfamiliar with speaking patterns."
                            else 
                               w$= "Unclear Sound." 
    endif 
	
	if originaldur>=60 and speakingtot>=polish and f1norm<=395 and eeee<=395
		warning0$ = "NO WARNING"
		else
		warning0$ = "WARNING"
     endif  
	 if originaldur<60 
		warning1$ = "your speech lasts less than 60 seconds; it might affect the accuracy of your speech assessment" 
			else 
			warning1$ = " " 
	endif

	 if speakingtot<polish 
		warning2$ = "Your speech is limited in content with long pause; it might affect the accuracy of your speech assessment" 
			else 
			warning2$ = " "	
	endif
	if f1norm>395 or eeee>395
		warning3$ = "There could be something wrong with your audio system OR your recorded voice is not clear OR your pronunciation level is limited"
			else
				warning3$ = " "
	endif
	   
if inpro>=119 and ('f1norm'*1.1)>=f1lowlim 
	r$ = "Native pronunciation level." 
		elsif inpro>=119 and ('f1norm'*1.1)<f1lowlim 
			r$ = "Native-like pronunciation level." 
				elsif inpro<119 and inpro>=100 and ('f1norm'*1.1)>=f1lowlim 
					r$ = "Mastery of the sound system of English, accurate pronunciation in most instances." 
						elsif inpro<119 and inpro>=100 and ('f1norm'*1.1)<f1lowlim 
							r$ = "Your level indicates that your pronunciation is generally accurate and ineligible, however, you can make your speech more natural if considering the stressed and weak sounds in words; for example, the second syllable of BANANA is stressed and the first and third are weak. " 
								elsif inpro<100 and inpro>=80 and ('f1norm'*1.1)>=f1lowlim 
									r$ = "Your level indicates that your pronunciation is mostly ineligible. You need to work on short vowels and diphthongs such as in day and triphthongs such as in here." 
									elsif inpro<100 and inpro>=80 and ('f1norm'*1.1)<f1lowlim 
									r$ = "Your level indicates that your pronunciation is fairly ineligible. You need to work on voiced/voiceless consonants, short vowels and diphthongs such as in day and triphthongs such as in here. Also you need to consider the stressed and weak sounds in words; for example, the second syllable of BANANA is stressed and the first and third are weak and also consider the stressed and weak words in speech; for example, in the order GO TO BED GO and BED are stressed and TO is not." 
								elsif inpro<80 and inpro>=70 and ('f1norm'*1.1)>=f1lowlim 
							r$ = "Your level suggests that your speech has minor difficulties with pronunciation or hesitate when creating speech.You need to work on voiced/voiceless consonants, short vowels and diphthongs such as in day and triphthongs such as in here. Also you need to consider the stressed and weak sounds in words; for example, the second syllable of BANANA is stressed and the first and third are weak and also consider the stressed and weak words in speech; for example, in the order GO TO BED GO and BED are stressed and TO is not." 
						elsif inpro<70 and inpro>=60 and ('f1norm'*1.1)>=f1lowlim
							r$ = "Your level suggests that your speech has some difficulties with pronunciation or hesitate when creating speech. You need to work on voiced/voiceless consonants, short vowels and diphthongs such as in day and triphthongs such as in here. Also you need to consider the stressed and weak sounds in words; for example, the second syllable of BANANA is stressed and the first and third are weak and also consider the stressed and weak words in speech; for example, in the order GO TO BED GO and BED are stressed and TO is not." 
					elsif inpro<70 and inpro>=60 and ('f1norm'*1.1)<f1lowlim
						r$ = "Your level indicates that your speech has few unclear pronunciation or inappropriate word-stress when you must create language. You need to work on voiced/voiceless consonants, short vowels and diphthongs such as in day and triphthongs such as in here. Also you need to consider the stressed and weak sounds in words; for example, the second syllable of BANANA is stressed and the first and third are weak and also consider the stressed and weak words in speech; for example, in the order GO TO BED GO and BED are stressed and TO is not." 
				else 
					r$ = "Unclear speech AND/OR unclear pronunciation and inappropriate word-stress or hesitate when creating speech.You need to work on voiced/voiceless consonants, short vowels and diphthongs such as in day and triphthongs such as in here. Also you need to consider the stressed and weak sounds in words; for example, the second syllable of BANANA is stressed and the first and third are weak and also consider the stressed and weak words in speech; for example, in the order GO TO BED GO and BED are stressed and TO is not." 
endif 
                              
#SCORING 
if f00<90 or f00>255 
         z=1.16 
               elsif f00<97 or f00>245 
                     z=2
                           elsif f00<115 or f00>245 
                                z=3
                     elsif f00<=245 or f00>=115 
						z=4
						else 
                         z=1                      
    endif

	if nuofwrdsinchunk>=6.24 and avepauseduratin<=1.0
		l=4
			elsif nuofwrdsinchunk>=6.24 and avepauseduratin>1.0
				l=3.6
					elsif nuofwrdsinchunk>=4.4 and nuofwrdsinchunk<=6.24 and avepauseduratin<=1.15
						l=3.3
							elsif nuofwrdsinchunk>=4.4 and nuofwrdsinchunk<=6.24 and avepauseduratin>1.15
								l=3
									elsif nuofwrdsinchunk<4.4 and avepauseduratin<=1.15
										l=2
											elsif nuofwrdsinchunk<=4.4 and avepauseduratin>1.15
												l=1.16
													else
														l=1
		endif
	if balance>=0.69 and avenumberofwords>=2.60 
		o=4
             elsif balance>=0.60 and avenumberofwords>=2.43  
               o=3.5 
			elsif balance>=0.5 and avenumberofwords>=2.25 
				o=3 
					elsif balance>=0.5 and avenumberofwords>=2.07 
						o=2 
						elsif balance>=0.5 and avenumberofwords>=1.95 
							o=1.16 
								else 
									o=1
		endif
	if speakingrate<=4.26 and speakingrate>=3.16 
           q=4    
             elsif speakingrate<=3.16 and speakingrate>=2.54 
               q=3.5
		elsif speakingrate<=2.54 and speakingrate>=1.91 
			q=3
                 elsif speakingrate<=1.91 and speakingrate>=1.28  
                     q=2    
                       elsif speakingrate<=1.28 and speakingrate>=1.0 
                         q=1.16         
                           else 
                             q=1        
		endif
	if balance>=0.69 and articulationrate>=4.54 
           w=4
             elsif balance>=0.60 and articulationrate>=4.22 
               w=3.5
		elsif balance>=0.50 and articulationrate>=3.91
			w=3
                 elsif balance>=0.5 and articulationrate>=3.59  
                     w=2
                       elsif balance>=0.5 and articulationrate>=3.10 
                          w=1.16
                             else 
                                w=1 
    endif       
	if inpro>=119 and ('f1norm'*1.1)>=f1lowlim
		r = 4
			elsif inpro>=119 and ('f1norm'*1.1)<f1lowlim
				r = 3.8	
					elsif inpro<119 and inpro>=100 and ('f1norm'*1.1)>=f1lowlim
						r = 3.6
							elsif inpro<119 and inpro>=100 and ('f1norm'*1.1)<f1lowlim
								r = 3.4
									elsif inpro<100 and inpro>=80 and ('f1norm'*1.1)>=f1lowlim
										r= 3.2
								elsif inpro<100 and inpro>=80 and ('f1norm'*1.1)<f1lowlim
									r = 2.8
							elsif inpro<80 and inpro>=70 and ('f1norm'*1.1)>=f1lowlim
								r = 2.4
						elsif inpro<70 and inpro>=60 and ('f1norm'*1.1)>=f1lowlim
							r = 2
					elsif inpro<70 and inpro>=60 and ('f1norm'*1.1)<f1lowlim
						r = 1.1
				else 
					r = 0.3 				
								
	endif 

# summarize SCORE in Info window
   totalscore =(l*2+z*4+o*3+q*3+w*4+r*4)/20

totalscale= 'totalscore'*25


if totalscore>=4 
Blue 
	s$="Excellent" 
	elsif totalscore>=3.80 and totalscore<4 
	s$="Very good" 
	elsif totalscore>=3.60 and totalscore<3.80 
	s$="Very good" 
	elsif totalscore>=3.5 and totalscore<3.6 
	s$="Good+" 
	elsif totalscore>=3.3 and totalscore<3.5 
	s$="Good" 
	elsif totalscore>=3.15 and totalscore<3.3 
	s$="Fair++" 
	elsif totalscore>=3 and totalscore<3.15 
	s$="Fair+"
	elsif totalscore>=2.83 and totalscore<3 
	s$="Fair" 
	elsif totalscore>=2.60 and totalscore<2.83 
	s$="Average++" 
	elsif totalscore>=2.5 and totalscore<2.60 
	s$="Average+" 
	elsif totalscore>=2.30 and totalscore<2.50 
	s$="Average" 
	elsif totalscore>=2.15 and totalscore<2.30 
	s$="Limited-Up" 
	elsif totalscore>=2 and totalscore<2.15 
	s$="Limited-average" 
	elsif totalscore>=1.83 and totalscore<2 
	s$="Limited" 
	elsif totalscore>=1.66 and totalscore<1.83 
	s$="Limited-Quite" 
	elsif totalscore>=1.50 and totalscore<1.66 
	s$="Limited-Low" 
	elsif totalscore>=1.33 and totalscore<1.50 
	s$="Very limited" 
	else 
	s$="Weak" 
endif

if totalscore>=3.6  
      a=4
       elsif totalscore>=0.6 and totalscore<2   
         a=1
	   elsif totalscore>=2 and totalscore<3
            a=2
              elsif totalscore>=3 and totalscore<3.6
                a=3
                   else
                     a=0.5   
 endif

if totalscale>=90  
      s=4
       elsif totalscale>=15 and totalscale<50   
         s=1
	   elsif totalscale>=50 and totalscale<75
            s=2
              elsif totalscale>=75 and totalscale<90
                s=3
                   else
                     s=0.5   
endif

#vvv=a+('totalscale'/100)
vvv=totalscore+('totalscale'/100)

if vvv>=4
     u=4*(1-(randomInteger(1,16)/100))
	else 
	   u=vvv-(randomInteger(1,16)/100) 
endif

if totalscore>=4
	xx=30 
	elsif totalscore>=3.80 and totalscore<4 
	xx=29 
	elsif totalscore>=3.60 and totalscore<3.80 
	xx=28 
	elsif totalscore>=3.5 and totalscore<3.6 
	xx=27 
	elsif totalscore>=3.3 and totalscore<3.5 
	xx=26 
	elsif totalscore>=3.15 and totalscore<3.3 
	xx=25 
	elsif totalscore>=3.08 and totalscore<3.15 
	xx=24
	elsif totalscore>=3 and totalscore<3.08 
	xx=23
	elsif totalscore>=2.83 and totalscore<3 
	xx=22 
	elsif totalscore>=2.60 and totalscore<2.83 
	xx=21 
	elsif totalscore>=2.5 and totalscore<2.60 
	xx=20 
	elsif totalscore>=2.30 and totalscore<2.50 
	xx=19 
	elsif totalscore>=2.23 and totalscore<2.30 
	xx=18
	elsif totalscore>=2.15 and totalscore<2.23 
	xx=17
	elsif totalscore>=2 and totalscore<2.15 
	xx=16 
	elsif totalscore>=1.93 and totalscore<2 
	xx=15
	elsif totalscore>=1.83 and totalscore<1.93 
	xx=14
	elsif totalscore>=1.74 and totalscore<1.83 
	xx=13
	elsif totalscore>=1.66 and totalscore<1.74 
	xx=12
	elsif totalscore>=1.50 and totalscore<1.66 
	xx=11 
	elsif totalscore>=1.33 and totalscore<1.50 
	xx=10 
	else 
	xx=9 
endif

overscore = xx*4/30
ov = overscore


if s$="L1" 
	level$= " This level shows the speaker may have the capacity to deal with material which is academic or cognitively demanding and to use language effectively at a level of performance which may in certain respects be more advanced than that of an average native speaker. Further, the speaker can communicate with the emphasis on how well it is done, regarding appropriately, sensitivity and the capacity to achieve most goals and express oneself on a range of topics."
		elsif s$="L2" 
			level$= "This level shows the speaker has the ability to express oneself in a limited way in familiar situations and to deal in a general way with non-routine information. Overall, that is an upper-intermediate qualification. It covers the use of English in real-life situations and study environments. Speakers are expected to express the main ideas of a range of topics, demonstrate different speaking styles such as discussion, storytelling, and keep up in conversations on a broad spectrum of topics, expressing opinions, presenting arguments and producing spontaneous spoken language." 
	   elsif s$="L3"
		level$="This level shows the speaker can deal with simple, straightforward information and begin to express oneself in familiar contexts, communicate with English speakers who talk slowly and clearly and speak short messages, can understand general questions, instructions, and phrases, can express simple opinions and needs. Speakers can follow everyday, practical English, such as following straightforward instructions & public announcements, taking part in factual conversations can interact with English speakers who talk slowly, completing forms and building short messages."
		  elsif s$="L4"
			level$="This level shows the speaker has a basic ability to communicate & efficiently exchange information in a simple way can understand simple spoken stories, take part in basic, factual conversations and express simple sentences using words provided."
	else
	  level$= "Beginner"
endif

qaz = 0.18

rr = (r*4+q*2+z*1)/7
lu = (l*1+w*2+inpro*4/125)/4
td = (w*1+o*2+inpro*1/125)/3.25
facts=(ln(7/4)*4/7+ln(7/2)*2/7+ln(7)*1/7+ln(4)*1/4+ln(2)*1/2+ln(4)*1/4+ln(3.25)*1/3.25+ln(3.25/2)*2/3.25+ln(3.25/0.25)*0.25/3.25+ln(14.25/7)*7/14.25+ln(14.25/4)*4/14.25+ln(14.25/3.35)*3.25/14.25)
#totsco = (r*ln(7/4)*4/7+q*ln(7/2)*2/7+z*ln(7)*1/7+l*ln(4)*1/4+w*ln(2)*1/2+ln(4)*1/4*inpro*4/125+w*ln(3.25)*1/3.25+o*ln(3.25/2)*2/3.25+ln(3.25/0.25)*0.25/3.25*inpro*4/125)/facts

if totalscore>=4
      totsco=3.9
       else
         totsco=totalscore  
 endif

rrr = rr*qaz
lulu = lu*qaz
tdtd = td*qaz
totscoo = totsco*qaz 
               
Font size... 8
Blue
	Draw arc... 0 0 (4*qaz) 0 90 
        Text... (3.5*qaz) Centre 0 Half 'Good'
Green
	Draw arc... 0 0 (3*qaz) 0 90  
        Text... (2.5*qaz) Centre 0 Half 'Fair'
Maroon
	Draw arc... 0 0 (2*qaz)  0 90 
        Text... (1.5*qaz) Centre 0 Half 'Limited'
Red
	Draw arc... 0 0 (1*qaz) 0 90  
        Text... (0.5*qaz) Centre 0 Half 'Weak'
Black
	Draw line... 0 0 0 6*qaz

whx=rrr*cos(1.309)
why=rrr*sin(1.309)
who=4*qaz
		
Font size... 10
if totsco>=3.17
	Blue
	Draw circle... (totscoo)*cos(0.5236) (totscoo)*sin(0.5236)+0.75*qaz (qaz/60)
		Text...  (totscoo)*cos(0.5236) Left (totscoo)*sin(0.5236)+2*(qaz/10)+0.75*qaz Half 'Overall-Score'
		Draw arc... 0 0 totscoo 30 31 
		elsif totsco>=2.17 and totsco<3.17
		Green
		Draw circle... (totscoo)*cos(0.5236) (totscoo)*sin(0.5236)+0.5625*qaz (qaz/60)
		Text...  (totscoo)*cos(0.5236) Left (totscoo)*sin(0.5236)+2*(qaz/10)+0.5625*qaz Half 'Overall-Score'
		Draw arc... 0 0 totscoo 30 31	
		elsif totsco>=1.17 and totsco<2.17
		Maroon
		Draw circle... (totscoo)*cos(0.5236) (totscoo)*sin(0.5236)+0.37*qaz (qaz/60)
		Text...  (totscoo)*cos(0.5236) Left (totscoo)*sin(0.5236)+2*(qaz/10)+0.37*qaz Half 'Overall-Score'
		Draw arc... 0 0 totscoo 30 31	
		else
		Red
		Draw circle... (totscoo)*cos(0.5236) (totscoo)*sin(0.5236)+0.1875*qaz (qaz/60)
		Text...  (totscoo)*cos(0.5236) Left (totscoo)*sin(0.5236)+2*(qaz/10)+0.1875*qaz Half 'Overall-Score'
		Draw arc... 0 0 totscoo 30 31		
endif				

Font size... 8

if rr>=3.17
	Blue
	Draw circle... whx why+1.8*qaz (qaz/60)
	Text... whx Centre why+3*(qaz/10)+1.8*qaz Half 'Delivery'
	Draw arc... 0 0 rrr 75 76
	elsif rr>=2.17 and rr<3.17
	Green
	Draw circle... whx why+1.35*qaz (qaz/60)
	Text... whx Centre why+3*(qaz/10)+1.35*qaz Half 'Delivery'
	Draw arc... 0 0 rrr 75 76	
	elsif rr>=1.17 and rr<2.17
	Maroon
	Draw circle... whx why+0.9*qaz (qaz/60)
	Text... whx Centre why+3*(qaz/10)+0.9*qaz Half 'Delivery'
	Draw arc... 0 0 rrr 75 76
	else
	Red
	Draw circle... whx why+0.33*qaz (qaz/60)
	Text... whx Centre why+3*(qaz/10)+0.33*qaz Half 'Delivery'
	Draw arc... 0 0 rrr 75 76		
endif				

if lu>=3.17				
	Blue
	Draw circle... lulu*cos(0.785398) lulu*sin(0.785398)+qaz (qaz/60)
	Text... lulu*cos(0.785398) Left lulu*sin(0.785398)+3*(qaz/10)+qaz Half 'Language use'
	Draw arc... 0 0 lulu 45 46
	elsif lu>=2.17 and lu<3.17
	Green
	Draw circle... lulu*cos(0.785398) lulu*sin(0.785398)+0.75*qaz (qaz/60)
	Text... lulu*cos(0.785398) Left lulu*sin(0.785398)+3*(qaz/10)+0.75*qaz Half 'Language use'
	Draw arc... 0 0 lulu 45 46	
	elsif lu>=1.17 and lu<2.17
	Maroon
	Draw circle... lulu*cos(0.785398) lulu*sin(0.785398)+0.5*qaz (qaz/60)
	Text... lulu*cos(0.785398) Left lulu*sin(0.785398)+3*(qaz/10)+0.5*qaz Half 'Language use'
	Draw arc... 0 0 lulu 45 46	
	else
	Red
	Draw circle... lulu*cos(0.785398) lulu*sin(0.785398)+0.25*qaz (qaz/60)
	Text... lulu*cos(0.785398) Left lulu*sin(0.785398)+3*(qaz/10)+0.25*qaz Half 'Language use'
	Draw arc... 0 0 lulu 45 46			
endif
				
if td>=3.17
	Blue
	Draw circle... tdtd*cos(1.0472) tdtd*sin(1.0472)+1.3*qaz (qaz/60)
	Text... tdtd*cos(1.0472) Centre tdtd*sin(1.0472)+3*(qaz/10)+1.3*qaz Half 'Topic development'
	Draw arc... 0 0 tdtd 60 61 
	elsif td>=2.17 and td<3.17
	Green
	Draw circle... tdtd*cos(1.0472) tdtd*sin(1.0472)+0.975*qaz (qaz/60)
	Text... tdtd*cos(1.0472) Centre tdtd*sin(1.0472)+3*(qaz/10)+0.975*qaz Half 'Topic development'
	Draw arc... 0 0 tdtd 60 61 	
	elsif td>=1.17 and td<2.17
	Maroon
	Draw circle... tdtd*cos(1.0472) tdtd*sin(1.0472)+0.65*qaz (qaz/60)
	Text... tdtd*cos(1.0472) Centre tdtd*sin(1.0472)+3*(qaz/10)+0.65*qaz Half 'Topic development'
	Draw arc... 0 0 tdtd 60 61 	
	else
	Red
	Draw circle... tdtd*cos(1.0472) tdtd*sin(1.0472)+0.325*qaz (qaz/60)
	Text... tdtd*cos(1.0472) Centre tdtd*sin(1.0472)+3*(qaz/10)+0.325*qaz Half 'Topic development'
	Draw arc... 0 0 tdtd 60 61 		
				
endif

Font size... 9
Black
Text... 2.65*qaz Left 5.5*qaz Half Overall-Score
Font size... 6
Text... 2.65*qaz Left 5*qaz Half of Standard English that is the more natural, 
Text... 2.65*qaz Left 4.85*qaz Half intelligible, widespread mode of speech in
Text... 2.65*qaz Left 4.7*qaz Half a spontaneous and question context. 
Text... 4.5*qaz Left 5.5*qaz Half 1-PRONUNCIATION
Text... 4.5*qaz Left 4.75*qaz Half 2-INTONATION-STRESS
Text... 4.5*qaz Left 4*qaz Half 3-FLUENCY
Text... 4.5*qaz Left 3.25*qaz Half 4-STRUCTURE
Text... 4.5*qaz Left 2.5*qaz Half 5-COMPREHENSIBILITY
Text... 4.5*qaz Left 1.75*qaz Half 6-IDEAS DEVELOPMENT

if f00<90 or f00>255 
	Maroon
	Text... 4.5*qaz Left 4.5*qaz Half Not much natural
	elsif f00<97 or f00>245 
	Green
	Text... 4.5*qaz Left 4.5*qaz Half Fairly natural
	elsif f00<115 or f00>245 
	Blue
	Text... 4.5*qaz Left 4.5*qaz Half Natural 	
	elsif f00<=245 and f00>=115
	Text... 4.5*qaz Left 4.5*qaz Half Very natural 
	else
	Red
	Text... 4.5*qaz Left 4.5*qaz Half Not natural
endif

if nuofwrdsinchunk>=6.24 and avepauseduratin<=1.0 
	Blue
	Text... 4.5*qaz Left 3*qaz Half Mastery
	elsif nuofwrdsinchunk>=6.24 and avepauseduratin>1.0 
	Text... 4.5*qaz Left 3*qaz Half Excellent command 
	elsif nuofwrdsinchunk>=4.4 and nuofwrdsinchunk<=6.24 and avepauseduratin<=1.15 
	Green
	Text... 4.5*qaz Left 3*qaz Half Very good command 
	elsif nuofwrdsinchunk>=4.4 and nuofwrdsinchunk<=6.24 and avepauseduratin>1.15 
	Text... 4.5*qaz Left 3*qaz Half Good command 
	elsif nuofwrdsinchunk<4.4 and avepauseduratin<=1.15 
	Maroon
	Text... 4.5*qaz Left 3*qaz Half Threshold 
	elsif nuofwrdsinchunk<=4.4 and avepauseduratin>1.15
	Red
	Text... 4.5*qaz Left 3*qaz Half Waystage 
	else
	Text... 4.5*qaz Left 3*qaz Half Breakthrough 
endif
 
if balance>=0.69 and avenumberofwords>=2.60 
	Blue
	Text... 4.5*qaz Left 2.25*qaz Half Mastery
	elsif balance>=0.60 and avenumberofwords>=2.43 
	Green
	Text... 4.5*qaz Left 2.25*qaz Half Effective-Proficiency 
	elsif balance>=0.5 and avenumberofwords>=2.25 
	Text... 4.5*qaz Left 2.25*qaz Half Vantage 
	elsif balance>=0.5 and avenumberofwords>=2.07 
	Maroon
	Text... 4.5*qaz Left 2.25*qaz Half Good knowledge 
	elsif balance>=0.5 and avenumberofwords>=1.95 
	Red
	Text... 4.5*qaz Left 2.25*qaz Half Waystage 
	else 
	Text... 4.5*qaz Left 2.25*qaz Half Breakthrough 
endif

if speakingrate<=4.26 and speakingrate>=3.16 
	Blue
	Text... 4.5*qaz Left 3.75*qaz Half Native-like
	elsif speakingrate<=3.16 and speakingrate>=2.54 
	Green
	Text... 4.5*qaz Left 3.75*qaz Half Fluent 
	elsif speakingrate<=2.54 and speakingrate>=1.91 
	Maroon
	Text... 4.5*qaz Left 3.75*qaz Half Excellent  
	elsif speakingrate<=1.91 and speakingrate>=1.28	
	Text... 4.5*qaz Left 3.75*qaz Half Good 	
	elsif speakingrate<=1.28 and speakingrate>=1.0
	Red
	Text... 4.5*qaz Left 3.75*qaz Half Average 
	else
	Text... 4.5*qaz Left 3.75*qaz Half Basic  
endif

if balance>=0.69 and articulationrate>=4.54 
	Blue
	Text... 4.5*qaz Left 1.5*qaz Half Professional 
	elsif balance>=0.60 and articulationrate>=4.22 
	Text... 4.5*qaz Left 1.5*qaz Half Effective-Proficiency 
	elsif balance>=0.50 and articulationrate>=3.91 
	Green
	Text... 4.5*qaz Left 1.5*qaz Half Very good working knowledge 
	elsif balance>=0.5 and articulationrate>=3.59 
	Maroon
	Text... 4.5*qaz Left 1.5*qaz Half Good working knowledge  
	elsif balance>=0.5 and articulationrate>=3.10 
	Red
	Text... 4.5*qaz Left 1.5*qaz Half Average working knowledge 
	else
	Text... 4.5*qaz Left 1.5*qaz Half Basic working knowledge
endif	
	
if inpro>=119 and ('f1norm'*1.1)>=f1lowlim 
	Blue
	Text... 4.5*qaz Left 5.25*qaz Half Native 
	elsif inpro>=119 and ('f1norm'*1.1)<f1lowlim 
	Text... 4.5*qaz Left 5.25*qaz Half Native-like 
	elsif inpro<119 and inpro>=100 and ('f1norm'*1.1)>=f1lowlim
	Text... 4.5*qaz Left 5.25*qaz Half Fluent 
	elsif inpro<119 and inpro>=100 and ('f1norm'*1.1)<f1lowlim
	Text... 4.5*qaz Left 5.25*qaz Half Excellent
	elsif inpro<100 and inpro>=80 and ('f1norm'*1.1)>=f1lowlim
	Green
	Text... 4.5*qaz Left 5.25*qaz Half Very good 
	elsif inpro<100 and inpro>=80 and ('f1norm'*1.1)<f1lowlim
	Text... 4.5*qaz Left 5.25*qaz Half Good 
	elsif inpro<80 and inpro>=70 and ('f1norm'*1.1)>=f1lowlim
	Maroon
	Text... 4.5*qaz Left 5.25*qaz Half Average 
	elsif inpro<70 and inpro>=60 and ('f1norm'*1.1)>=f1lowlim 
	Text... 4.5*qaz Left 5.25*qaz Half Breakthrough 
	elsif inpro<70 and inpro>=60 and ('f1norm'*1.1)<f1lowlim
	Red
	Text... 4.5*qaz Left 5.25*qaz Half Basic
	else
	Text... 4.5*qaz Left 5.25*qaz Half Difficult-to-catch 
endif 

if originaldur>=60 
	Text... 4.5*qaz Left 1*qaz Half 
	else 
	Text... 4.5*qaz Left 1*qaz Half **speech lasts less than 60 secs 
endif 
if speakingtot>=polish 
	Text... 4.5*qaz Left 0.75*qaz Half 
	else 
	Text... 4.5*qaz Left 0.75*qaz Half **Your speech has long pauses 
	endif 
	if f1norm>395 or eeee>395 
	Text... 4.5*qaz Left 0.5*qaz Half **Your voice is not clear 
	else 
	Text... 4.5*qaz Left 0.5*qaz Half 
endif
	
Font size... 9
if totalscore>=4
Blue
	Text... 3.5*qaz Left 5.5*qaz Half 100'/, 
	elsif totalscore>=3.80 and totalscore<4 
	Text... 3.5*qaz Left 5.5*qaz Half 97'/, 
	elsif totalscore>=3.60 and totalscore<3.80 
	Text... 3.5*qaz Left 5.5*qaz Half 93'/, 
	elsif totalscore>=3.5 and totalscore<3.6 
	Text... 3.5*qaz Left 5.5*qaz Half 90'/, 
	elsif totalscore>=3.3 and totalscore<3.5 
	Text... 3.5*qaz Left 5.5*qaz Half 86'/, 
	elsif totalscore>=3.15 and totalscore<3.3 
	Text... 3.5*qaz Left 5.5*qaz Half 82'/, 
	elsif totalscore>=3 and totalscore<3.15 
	Text... 3.5*qaz Left 5.5*qaz Half 77'/, 
	elsif totalscore>=2.83 and totalscore<3 
	Text... 3.5*qaz Left 5.5*qaz Half 73'/, 
	elsif totalscore>=2.60 and totalscore<2.83 
	Text... 3.5*qaz Left 5.5*qaz Half 67'/, 
	elsif totalscore>=2.5 and totalscore<2.60 
	Text... 3.5*qaz Left 5.5*qaz Half 63'/,
	elsif totalscore>=2.30 and totalscore<2.50 
	Text... 3.5*qaz Left 5.5*qaz Half 60'/,
	elsif totalscore>=2.15 and totalscore<2.30 
	Text... 3.5*qaz Left 5.5*qaz Half 57'/, 
	elsif totalscore>=2 and totalscore<2.15 
	Text... 3.5*qaz Left 5.5*qaz Half 50'/, 
	elsif totalscore>=1.83 and totalscore<2 
	Text... 3.5*qaz Left 5.5*qaz Half 47'/, 
	elsif totalscore>=1.66 and totalscore<1.83 
	Text... 3.5*qaz Left 5.5*qaz Half 43'/, 
	elsif totalscore>=1.50 and totalscore<1.66 
	Text... 3.5*qaz Left 5.5*qaz Half 37'/, 
	elsif totalscore>=1.33 and totalscore<1.50 
	Text... 3.5*qaz Left 5.5*qaz Half 34'/, 
	else 
	Text... 3.5*qaz Left 5.5*qaz Half 25'/, 
endif

Save as 300-dpi PNG file... C:\Users\Sabahi.s\Desktop\MYSOL Scoring File\RESULTS/'soundname$'.jpg

Erase all

         writeFileLine: "C:\Users\Sabahi.s\Desktop\MYSOL Scoring File\RESULTS/'soundname$'.doc", newline$
	 ... ,"*************************************************************************", newline$
	 ... ,"*************************************************************************", newline$
	 ... ,"FILE NAME", tab$, tab$, tab$, soundname$, newline$
     ... ,"Number of words", tab$, tab$, 'nuofwrds:0', newline$   
     ... ,"Number of pauses", tab$, tab$, 'npause', newline$ 
   	 ... ,"Duration (s)", tab$, tab$, tab$,'originaldur:2', newline$
   	 ... ,"Phonation time (s)", tab$, tab$,'speakingtot:2', newline$
	 ... ,"*************************************************************************", newline$
   	 ... ,"*************************************************************************", newline$	 
	 ... ,warning0$, newline$
	 ... ,warning1$, newline$ 
	 ... ,warning2$, newline$
	 ... ,warning3$, newline$
	 ... ,"*************************************************************************", newline$
   	 ... ,"*************************************************************************", newline$
   	 ... ,"Overall Score ---TOEFL iBT Score scale between 0 (low) and 30 (high)--",'xx:1', newline$
	 ... ,"Overall Band Level ----Level scale: Weak, Limited, Fair, Good --",s$, newline$
 	 ... ,"*************************************************************************", newline$
   	 ... ,"*************************************************************************", newline$	 
	 ... ,"PRONUNCIATION", newline$										
   	 ... , r$, newline$												  
   	 ... ,"------------------------------------------------------------------------", newline$
   	 ... ,"INTONATION and STRESS", newline$									
   	 ... , z$, newline$	  
   	 ... ,"------------------------------------------------------------------------", newline$
   	 ... ,"FLUENCY in SPEECH", newline$			
   	 ... , q$, newline$					
  	 ... ,"------------------------------------------------------------------------", newline$
   	 ... ,"STRUCTURE*", newline$					
   	 ... , l$, newline$				
  	 ... ,"------------------------------------------------------------------------", newline$
   	 ... ,"COHERENCE and COMPREHENSIBILITY**", newline$							 
   	 ... , o$, newline$				
   	 ... ,"------------------------------------------------------------------------", newline$ 
   	 ... ,"IDEAS DEVELOPMENT****", newline$								
   	 ... , w$, newline$
   	 ... ,"*********************************************************", newline$
   	 ... ,"* An indicator for grammar, standard English expressions and vocab use, ", newline$   
   	 ... ,"** The indicator reflects the logical structure of speech, vocabulary use, ", newline$
   	 ... ,"*** An indicator for developing ideas, opinions, and speech.", newline$
	 ... ,"------------------------------------------------------------------------", newline$
	 ... ,"------------------------------------------------------------------------", newline$
endfor

