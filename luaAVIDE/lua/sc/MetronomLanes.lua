--- MetronomLanes
--require"init"
--require"sc.playersppq"

theMetro={bpm=120,bps=2,beat=0,rate=100,ppqPos=0,playing=0,frame=1,playNotifyCb={},abstime=0}
--EP for computing abstime
--[[
function updateAbsTime(p)
	p.abstimeAcum = p.abstimeAcum + (p.ppqPos - p.ppqPosSave )/theMetro.bps
	p.ppqPosSave = p.ppqPos
	theMetro.abstime = p.abstimeAcum
	--print(theMetro.player.ppqPos,theMetro.ppqPosSave,theMetro.bps,theMetro.ppqPos)
	return 1
end
theMetro.player = EP{ppqPosSave=0,abstimeAcum=0,name="MetroPlayer"}
theMetro.player:Bind{dur = 0.5,
	abst = FS(updateAbsTime,-1,theMetro.player)
}
function theMetro:Init()
	self.abstimeAcum = 0
	self.ppqPosSave = 0
end
--]]
------------------------------------------
function getHostTime()
	return theMetro
end
function theMetro:GOTO(beat)
	self:play(nil,beat)
end
function theMetro:play(bpm,beat,run,rate)
	if bpm then self:tempo(bpm) end
	if beat then self.ppqPos=beat; theMetro.oldtimestamp = lanes.now_secs() end
	--self.beat=self.ppqPos
	if rate then self.rate=rate end
	--self.frame=self.bpm/(self.rate*60)
	self.frame=self.bps/self.rate
	self.period=1/self.rate
	if run then self.playing=run end
	
	--print("cambio reloj",bpm,beat,rate)
	--prtable(self)
	
	if self.playing==1 then
		self:start()
	else
		self:stop()
	end
	--lanes.timer(scriptlinda,"metronomLanes",self.period,self.period)
	for k,v in ipairs(self.playNotifyCb) do
		v(self)
	end
end

function theMetro:tempo(bpm)
	--self.abstimeAcum = self.abstimeAcum + (self.player.ppqPos - self.ppqPosSave )/self.bps
	--print(self.abstimeAcum)
	--self.ppqPosSave = self.player.ppqPos
	self.bpm=bpm;
	self.bps=bpm/60
end

function theMetro:Free()
	self.playing=0
end
function theMetro:start()
	--print("start reloj")
	self.playing=1
	theMetro.oldtimestamp = lanes.now_secs()
	--lanes.timer(scriptlinda,"metronomLanes",self.period,0)--self.period)
	lanes.timer(scriptlinda,"metronomLanes",self.period,self.period)
end
function theMetro:stop()
	--print("paro reloj")
	self.playing=0
	lanes.timer(scriptlinda,"metronomLanes",0)
end

function theMetro:ppq2time(ppq)
	return self.timestamp + (ppq - self.oldppqPos) / self.bps
end

function setMetronomLanes(timestamp)
	--print("setMetronomLanes")
	if theMetro.oldtimestamp then
		theMetro.realperiod = timestamp - theMetro.oldtimestamp
		local errorl =(theMetro.realperiod - theMetro.period) --*theMetro.rate
		if  math.abs(errorl) >= theMetro.period then
			prerror("error metronomLanes ",errorl*theMetro.rate,lanes.now_secs()-timestamp)
		end
	else
		theMetro.realperiod = theMetro.period
	end
	theMetro.timestamp = timestamp
	--theMetro.abstime = theMetro.abstimeAcum + (theMetro.player.ppqPos - theMetro.ppqPosSave) / theMetro.bps
	 
	theMetro.oldppqPos = theMetro.ppqPos
	theMetro.ppqPos = theMetro.ppqPos + theMetro.bps * theMetro.realperiod 

	theMetro.abstime = theMetro.abstime + theMetro.realperiod
	
	_onFrameCb()

	theMetro.oldtimestamp = timestamp
	--lanes.timer(scriptlinda,"metronomLanes",theMetro.period,0)
	collectgarbage("collect")
end

theMetro:play(120,-4,0,100)
--table.insert(initCbCallbacks,function() print("init metronom");theMetro:play(120,-4,0,100) end)
resetCbCallbacks = resetCbCallbacks or {}
table.insert(resetCbCallbacks,function() theMetro:stop() end)