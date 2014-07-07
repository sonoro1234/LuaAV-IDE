lanes=require("lanes")
lanes.configure({ nb_keepers = 1, with_timers = true, on_state_create = nil,track_lanes=true}) --,verbose_errors=true})
av = {}
ffi = require"ffi"
ffi.cdef[[
	// Windows
	void Sleep(int ms);
	
	// unix
	int poll(struct pollfd *fds, unsigned long nfds, int timeout);
	struct timeval {
		long int tv_sec;
		long int tv_usec;
	};
	int gettimeofday(struct timeval *restrict tp, void *restrict tzp);
]]
ffi.cdef[[unsigned long timeGetTime(void);]]
winmm = ffi.load"Winmm.dll"
if ffi.os == "Windows" then
	function av.sleep(s)
		ffi.C.Sleep(s*1000)
	end
	
	lj_glfw = require"GLFW.glfw"
	local glfw = lj_glfw.glfw
	assert(glfw)
	av.time = glfw.glfwGetTime
	---[[
	local tv = ffi.new("struct timeval[1]")
	local function time()
		ffi.C.gettimeofday(tv, nil)
		return tonumber(tv[0].tv_sec) + (tonumber(tv[0].tv_usec) * 1.0e-6)
	end
	local t0 = time()
	function av.time() return time() - t0 end
	--]]
	assert(av.time)
else
	function av.sleep(s)
		ffi.C.poll(nil, 0, s*1000)
	end
	local tv = ffi.new("struct timeval[1]")
	local function time()
		ffi.C.gettimeofday(tv, nil)
		return tonumber(tv[0].tv_sec) + (tonumber(tv[0].tv_usec) * 1.0e-6)
	end
	local t0 = time()
	function av.time() return time() - t0 end
end
lj_glfw.init()
local winmmt0 = winmm.timeGetTime()
function winmmtime()
	return (winmm.timeGetTime() - winmmt0)*0.001
end
local t0l = lanes.now_secs()
function lanestime()
	return lanes.now_secs() - t0l
end
while true do
	av.sleep(1)
	print(av.time(),lanestime(),av.time()-lanestime(),winmmtime(),lanestime()-winmmtime())
end