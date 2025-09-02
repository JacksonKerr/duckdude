pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- init & utils
local evnt_q={}
function run_evnt_q()
	for i=1,count(evnt_q) do
		evnt_q[i].t-=1
		local e=evnt_q[i]
		if (e.t==0)	e.f()
	end
	
	local new_q={}
	for o in all(evnt_q) do
		if (o.t>0)	add(new_q,o)
	end
	evnt_q=new_q
end

function at_home(o)
	return o.x<127 and o.y<255
end

function _init()
	printh("loaded")
	
	mvmt=true
	show_plr=true
	bus_enabled=false
	in_dialog=function() 
		return dlg_npc!=nil
	end
	
	fly_hack=true
	has_backpack=false
	
	prev_io={
		⬆️=false,⬇️=false,⬅️=false,
		➡️=false,❎=false,🅾️=false,
	}
	
	p=newplr(24,204,
		{77,78,79},"➡️")
	setup_npcs()
	
	cam_x=0 cam_y=0
	
	do_wipe(32,true)
end
-->8
-- collision
function movex(nx,o)
	local stp_h=2
	if (nx>0) o.dir="➡️"
	if (nx<0) o.dir="⬅️"
	local sign=1	if (nx<0) sign=-1
	local dx=abs(nx)
	while dx>0 do
		local newx = o.x+(sign*1)
		if (shwall(newx,o.y)) then
			if not shwall(newx,o.y-stp_h)
				then o.y-=stp_h
			else return end
		end
		if (newx>-1 and newx<128*8-7) 
		then o.x=newx end
		dx-=1
	end
end

function movey(ny, o)
	local sign=1 if (ny<0) sign=-1
	local dy=abs(ny)
	while dy>0 do
		local newy=flr(o.y+sign)
		if shwall(o.x,newy) then 
			if (ny>0) o.grounded=true
			if (ny<0) o.dy=0
			return
		end
		o.grounded=false
		o.y=newy
		dy-=1
	end
end

function bslb_col(blk,subx,suby)
	if (blk.top) return true
	return suby>4
end
function bbar_col(blk,subx,suby)
	if (blk.top) return true
	return suby>6
end
function tslb_col(blk,subx,suby)
	if (not blk.top) return true
	return suby<4
end
function vpil_col(blk,subx,suby)
	if blk.lft then
		if (subx<5)	return true 
	else 
		if (3<subx)	return true
	end
	return false
end
function hpil_col(blk,subx,suby)
	if blk.top then
		if (suby<5)	return true 
	else 
		if (3<suby)	return true
	end
	return false
end
function rrmp_col(blk,subx,suby)
	if (blk.top) return true
	if (blk.lft) return true
	if (subx+suby>8)	return true
	return false
end
function lrmp_col(blk,subx,suby)
	if (blk.top) return true
	if (not blk.lft) return true
	if (subx-suby<0)	return true
	return false
end

function blkcoll(blk,subx,suby)
	t=mget(blk.mx,blk.my)
	local f0=fget(t,0)
	local f1=fget(t,1)
	local f2=fget(t,2)
	local f3=fget(t,3)
	local f7=fget(t,7)

	if (blk.my>31 and f7) return false
	
	local solid=f0 and f1
		and not f2	and not f3
	local bslb=f0	and not f1
		and not f2	and not f3
	local tslb=not f0 and f1
		and not f2	and not f3
	local vpil=not f0	and not f1
		and f2	and not f3
	local hpil=f0	and f1
		and f2	and not f3
	local rrmp=f0	and not f1
		and f2	and not f3
	local lrmp=not f0	and f1
		and f2	and not f3
	local bbar=f0	and not f1
		and not f2	and f3
		
	
	if (solid) return true
	if (bslb) then 
		if bslb_col(blk,subx,suby) 
		then return true end
	end
	if (tslb) then
		if tslb_col(blk,subx,suby)
		 then return true end
	end
	if (vpil) then 
		if vpil_col(blk,subx,suby) 
		 then return true end
	end
	if (hpil) then 
		if hpil_col(blk,subx,suby) 
		 then return true end
	end
	if (rrmp) then 
		if rrmp_col(blk,subx,suby) 
		 then return true end
	end
	if (lrmp) then 
		if lrmp_col(blk,subx,suby) 
		 then return true end
	end
	if (bbar) then
		if bbar_col(blk,subx,suby) 
		 then return true end
	end
end

function shwall(x, y)
	local pmx=flr(x/8)
	local	pmy=flr(y/8)

	local blks={
		{
			mx=pmx,my=pmy,
			top=true,lft=true,
		},--⬆️⬅️
	}
	
	if x%8!=0 then 
	 	add(
		 	blks,
		 	{
					mx=pmx+1,my=pmy,
					top=true,lft=false,
				}--⬆️➡️
		 )
	end
	if (y%8!=0) then 
	 	add(
		 	blks,
		 	{
					mx=pmx,my=pmy+1,
					top=false,lft=true,
				}--⬆️➡️
		 )
	end
	if (count(blks)==3) then
		add(
	 	blks,
	 	{
				mx=pmx+1,my=pmy+1,
				top=false,lft=false,
			}--⬆️➡️
	 ) 
	end
	
	ret = false
	for blk in all(blks) do
		subx=x%8 suby=y%8
		if blkcoll(blk,subx,suby) then 
			ret=true
		end
	end
	return ret
end
-->8
-- player
function newplr(ix,iy,s,dir)
	return {
		x=ix,
		y=iy,
		
		x_accel=0.5,
		x_decel=0.5,
		vmax=2,
		
		gravity=0.5,
		terminal_velocity=4,
		jump_accel=-5,
		jumpholdmult=1.5,
		
		dx=0,dy=0,
		dir=dir,
		jmp=0,
		grounded=false,
		
		cs=s[1],--current sprite
		s=s,--walk anim sprites
	}
end

function upd_plr(o) 
	handle_dx(o) 
	handle_dy(o)
	
	if not prev_io.🅾️ and btn(🅾️)
	and not in_dialog() then	
		 if (indr_tog(o)) return 
	end
	if btn(🅾️) and not prev_io.🅾️
		then next_dialog(o) end
		
	movey(o.dy,o)
end	

function handle_dx(o) 
	if mvmt and btn(➡️)
	and not in_dialog() then
		if (o.x_accel > o.dx) o.dx=0
		if (o.dx<o.vmax) o.dx+=o.x_accel
	elseif mvmt and btn(⬅️) 
	and not in_dialog() then
		if (-o.x_accel < o.dx) o.dx=0
		if (o.dx>-o.vmax) o.dx-=o.x_accel
	else
		if (o.dx>0) o.dx-=o.x_decel
		if (o.dx<0) o.dx+=o.x_decel
	end
	movex(o.dx,o)
end

function handle_dy(o)
	if o.dy<o.terminal_velocity
		then o.dy+=o.gravity	end
	if (o.grounded) o.dy=0.001 

	if (not mvmt) return
	if btn(❎) 
		and (o.grounded or fly_hack)
		and not prev_io.❎
		and not in_dialog()
		then	o.dy=o.jump_accel	end
end

--transition
function indrs(o)
	if (o.y<250) return true
	return false
end

function indr_tog(o)
	bus_stop={
		x1=13*8,y1=27*8,
		x2=(15*8)+7,y2=(28*8)+7,
	}
	if (
		bus_enabled
		and o.x>=bus_stop.x1
		and o.y>=bus_stop.y1
		and o.x<=bus_stop.x2
		and o.y<=bus_stop.y2
	) then
		mvmt=false
		run_bus(104,208,false,
			function() 
				show_plr=false
			end,
			function()
				screen_wipe(
					function() 
						o.x=2*8 o.y=59*8
						o.dir="⬅️"
					end,
					function() 
						run_bus(0,59*8-3,true,
							function() 
							 show_plr=true
							 mvmt=true
							end
						)
					end
				)
				return true
			end
		)
		return false
	end
	
	-- center point of object
 mx=(o.x+4)/8	my=(o.y+4)/8
	if	fget(mget(mx,my),6) then
		mvmt=false
		screen_wipe(
			function() 
				if indrs(o) then o.y+=256
				else o.y-=256 end
			end,
			function() 
				mvmt=true
			end
		)
	end
end

-->8
--camera
function update_camera(o)
	local smth=2 --smoothing
	local new_x=p.x-63
	local delt_x=abs(new_x-cam_x)
	local new_y=p.y-80
	local delt_y=abs(new_y-cam_y)
	x_cam_bnds=function (old_x,x)
		if (x<0) return 0
		if (x>896) return 896
		if indrs(o) and x<128 then
			if (old_x>=128) return 128
			return 0
		end
		return x
	end

	if (delt_x>80)	then
		--snap on large camera move 
		new_x=cam_x+delt_x
	else
		if (cam_x>new_x) delt_x*=-1
		new_x=flr(cam_x+(delt_x/smth))
		new_x=x_cam_bnds(cam_x,new_x)
	end
	cam_x=flr(new_x)
	
	y_cam_bnds=function (y) 
		if indrs(o) then
			if (128<y)	return 128
		else
			if (384<y)	return 384
			if (y<256) return 256
		end
		return y
	end
	
	if (delt_y>80)	then
		--snap on large camera move 
		new_y=y_cam_bnds(
			cam_y+delt_y
		)
	else
		if (cam_y>new_y) delt_y*=-1
		new_y=flr(cam_y+(delt_y/smth))
		new_y=y_cam_bnds(new_y)
	end
	cam_y=flr(new_y)
	
	camera(cam_x,cam_y)
end
-->8
--dialogue & npcs
function new_npc(
	ix,iy,dir,name,
	idle_s,yap_s,
	dialog,
	pre_dlg_actn,post_dlg_actn
)
	return {
		name=name,
		x=ix,y=iy,
		dir=dir,
		cs=idle_s,
		idle_s=idle_s,
		yap_s=yap_s,
		dialog=dialog,
		pre_dlg_actn=pre_dlg_actn,
		post_dlg_actn=post_dlg_actn,
	}
end

function setup_npcs()
	seg=new_npc(100,182,"⬅️",
		"sam the seagul",110,111,
		{
			[[hi dan, how's things?]],
			[[you applied for planning permission for that project yet?]],
			[[well, the council should be open by now.]],
			[[the bus is about to swing past. there's no time like the present.]],
		},
		nil,
		spoke_to_seagul
	)
	
	kkereru=new_npc(60,480,"⬅️",
		"kevin the kereru",92,93,
		{
			[[oi, you! did the bus just come past?]],
			[[...]],
			[[aw man, i'm gonna be late for dinner 😐]]
		},
		nil,
		function() 
			screen_wipe(
				function()
					kkereru.x=2*8	
					kkereru.y=(59*8)+4	
					kkereru.dialog={
						[[guess i'll have to wait for the next one...]]
					}
					kkereru.post_dlg_actn=nil
				end
			)
		end
	)

	jmal=new_npc(264,220,"⬅️",
		"john mallard",94,95,
		{
			[[gidday, gidday. what are ya after?]],
			[[planning permission ay. ok, let's see here...]],
			[[the next available appointment is on...]],
			[[...]],
			[[the 7th of july at 5:15AM. have a good one, we'll seeya then.]],
			[[*phone rings*]],
			[[one sec. i gotta take this]],
			[[*on phone* gidday, john malard here.]],
			[[*on phone* no worries, that will incur a $450 cancelation fee.]],
			[[*on phone* well, you will have to take that up with the planning permission scheduling cancelation fee forgiveness team.]],
			[[*on phone* um, unfortunately they're a bit short staffed at the moment and their only team member is on leave]],
			[[*on phone* they should be back within the next 14 weeks.]],
			[[*on phone* kthxbye]],
			[[*hangs up*]],
			[[well sonny jim... sorry, see you at your appointment.]],
			[[what!? you think you can just march in and take up someone elses cancelled appointment!? well i never! theres protocol to follow here! never have i met a more presumptuous duck in all of my days on this earth!]],
			[[and don't call me shirley]],
			[[well...]],
			[[i suppose i can let it slide this one time...]],
			[[head up to the fifth floor, simon the sparrow will be waiting.]],
		},
		nil,
		given_appointment
	)
	sspar=new_npc(264,92,"⬅️",
		"simon the sparrow",126,127,
		{[[...]],}
	)
	ppukeko=new_npc(798,480,"⬅️",
		"percy the pukeko",124,125,
		{
			[[sorry mate, v.t.n.z's closed for smoko.]],
		}
	)
	ppidgeon=new_npc(665,220,"➡️",
		"polly the pidgeon",108,109,
		{
			[[give me a minute bro, we've just opened.]],
		}
	)
	
	jmoa=new_npc(806,214,"⬅️",
		"jason da-moa",75,76,
		{[[...]]}
	)
	
	bpellican=new_npc(
		48*8,19*8+4,"⬅️",
		"big bill",73,74,
		{
			[[...]],
		}
	)
	
	kkiwi=new_npc(
		58*8,27*8+4,"⬅️",
		"kelly the kiwi",122,123,
		{
			[[hya, welcome to specsavers.]],
			[[just here for a browse? sweet as. feel free to have a look around.]],
		}
	)
	
	npcs={ seg,kkereru,jmal,sspar,
		ppukeko,ppidgeon,jmoa,kkiwi,
		
		bpellican,
	}
end

dlg_npc=nil
dlg_ln=1
function draw_dialog()
	-- dialog
	if (dlg_npc==nil) return

	--print nameplate
	rectfill(
		cam_x+1,cam_y+1,
		cam_x+126,cam_y+7,
		15
	)
	print(
		dlg_npc.name,
		cam_x+2,cam_y+2,
		0
	)

	local l=
		dlg_npc.dialog[dlg_ln]
	local max_len=30
	local up_to=1
	local p_to=up_to+max_len+1
	local text_y=cam_y+8
	while up_to<#l do
		while sub(l,up_to,1)==" " do
			up_to+=1 
		end
		
		local p_to=up_to+max_len
		
		local l_chr=sub(l,p_to,p_to)
		if (p_to<#l) then
			while l_chr!=" " do
				p_to-=1
				l_chr=sub(l,p_to,p_to)
			end
		end
			
		rectfill(cam_x+1,text_y,cam_x+126,text_y+6,7)
		print(sub(l,up_to,p_to),cam_x+2,text_y+1,0)
		text_y+=7
		up_to=p_to+1
	end
end

function next_dialog(o)
	local try_f=function(f)
		if (f!=nil)	f()
	end

	local r=25
	if dlg_npc!=nil then
		dlg_ln+=1
		if dlg_ln>count(dlg_npc.dialog)
		then
			local f=dlg_npc.post_dlg_actn
			try_f(f)
			dlg_npc=nil	
		end
	elseif mvmt then
		for npc in all(npcs) do
			if abs(npc.x-o.x)<r
				and abs(npc.y-o.y)<r then
					local f=npc.pre_dlg_actn
					npc.pre_dlg_actn=nil
					try_f(f)
					dlg_npc=npc
					dlg_ln=1
					return
			end
		end
	end
end

function spoke_to_seagul()
	bus_enabled=true
	seg.dialog={
		[[the bus is almost here! you better get to the bus stop!]],
	}
end

function given_appointment()
	// open office door
	mset(28, 11, 44)
	mset(28, 12, 60)
	
	jmal.dialog={
		[[well, off you go then. he's up on the fifth floor.]]
	}
	sspar.dialog={
		[[hya, please take a seat---]],
		[[righty oh, doing a bit of d.i.y. are we? we'll see about that]],
		[[what did you have in mind?]],
		[[...]],
		[[well, it's ambitious but should be perfectly permissable, and you seem to have all the paperwork in order.]],
		[[i'll just need to see your i.d. then you can sign here.]],
	}
	sspar.post_dlg_actn=pass_id
end

function pass_id()
	sspar.pre_dlg_actn=
			function() 
				ui_elms.id.shown=true
			end
	sspar.dialog={
		[[*passes i.d.*]],
		[[ok great, just sign here ple--]],
		[[uh...]],
		[[...]],
		[[this id is out of date...]],
		[[listen here, i'm no pencil pushing bureaucrat like that fool downstairs but this simply won't do.]],
		[[now, i'll be honest. i was about clock out. it's already 8AM after all...]],
		[[but if you hurry down to to the v.t.n.z at the end of the street you should be able to get it renewed fairly quickly.]],
		[[i'll stick around for another few minutes just for you.]],
		[[hurry along now.]],
	}
	sspar.post_dlg_actn=
		setup_pukeko_lines
end

function setup_pukeko_lines()
		ui_elms.id.shown=false
		sspar.dialog={
			[[go on, get a move on down to v.t.n.z then. i'm keen to knock off.]]
		}
		ppukeko.dialog={
			[[sorry mate, v.t.n.z's closed for smoko.]],
			[[...]],
			[[in a hurry aye? well, get me a steak n' cheese from the servo next-door and i'll help you out.]],
		}
		ppukeko.post_dlg_actn=
				setup_servo_lines
end

function setup_servo_lines()
	ppidgeon.dialog={
		[[hya mate, what can i do ya for?]],
		[[...]],
		[[sweet as, here you go]],
		[[*new trade deal made*]],
		[[*aquired*: one 'steak' and cheese pie]],
	}
	ppidgeon.post_dlg_actn=
		setup_vtnz_dialog
end

function setup_vtnz_dialog()
	ppidgeon.dialog={
		[[sorry mate, that was the last one in the warmer.]],
	}
	ppukeko.dialog={
		[[cheers mate, i'll see you inside...]],
	}
	ppukeko.post_dlg_actn=
		give_pukeko_pie
end

function give_pukeko_pie()
	screen_wipe(
		function() 
			// move pukeko inside.
			ppukeko.x=(95*8+3)
			ppukeko.y=27*8
			
			// open vtnz door
			mset(92,59,12)
			mset(92,60,28)
			ppukeko.post_dlg_actn=nil
		end
	)
	
	ppukeko.dialog={
		[[ah, a licence renewal. you'll want to talk to jason the moa in the office.]],
		[[thanks for the pie!]],
	}
		
	// setup moa doalog.
	jmoa.dialog={
			[[percy tells me you need your id renewed.]],
			[[...]],
			[[yes, yes, that's me. the acting work has been a bit slow after the whole garett "the garbage man" thing.]],
			[[...]],
			[[yeah, and this joke doesen't even work because jason mamoa's hawaiian and i'm an extinct new zealand bird. can we just forget about it?]],
			[[anyway...]],
			[[unfortunately you're due an eye test so before i renew this, you'll have to pay a visit to specsavers.]],
			[[cya.]],
	}
	jmoa.post_dlg_actn=
		setup_specsavers
end

function setup_specsavers()
	jmoa.dialog={
			[[got those eye test results yet? no? well head down to specsavers. i can't renew this without it.]],
	}
	kkiwi.dialog={
		[[sup horn?]],
		[[...]],
		[[oh, sorry...]],
		[[i mean welcome to specsavers. how can i help you?]],
		[[..]],
		[[well then, join me upstairs and we'll get started.]],
	}
	kkiwi.post_dlg_actn=
		setup_eye_test
end

function setup_eye_test()
	//after moa, setup kiwi in
	//specsavers
	kkiwi.dialog={
		[[alright, what do you see?]],
		[[ok, ok]],
		[[which is better?]],
		[[left?]],
		[[or right?]],
		[[left?]],
		[[or right?]],
	}
	screen_wipe(
		function() 
			kkiwi.x=54*8
			kkiwi.y=23*8+4
		end
	)
end
-->8
--map detail & ui
-- todo: cull elms outside
-- of view
moving_elms={
	{--bus
		x=80,y=59*8,
		draw=function(x,y,flp)
			--bus is symmetrical
			pal(8,3)
			draw_bus(x,y,false)
			draw_bus(x+24,y,true)
			pal(8,8)
		end,
		upd=function(x,y)
			if (x>127*8) x=-48--width
			return x+2,y
		end
	},
	{--car
		x=0,y=61*8-2,
		draw=function(x,y,flp)
			pal(8,11)
			spr(112,x,y+8)
			spr(97,x+8,y,3,2)
			pal(8,8)
		end,
		upd=function(x,y)
			if (x<-64) x=127*8
			return x-2.5,y
		end
	},
}
function upd_moving_elms() 
	for i in pairs(moving_elms) do
		local e=moving_elms[i]
		if e.upd!=nil then
			e.x,e.y=e.upd(e.x,e.y)
		end
	end
end

function new_cloud(mx,my,x_wrp)
	return {
		x=mx*8,y=my*8,
		x_wrp=x_wrp or 127*8-1
	}
end
function upd_clouds(clouds)
	for cld in all(clouds) do
		if (cld.x>cld.x_wrp) cld.x=-39
		cld.x+=0.065
	end
end
function draw_clouds(clouds)
	--w39,h23
	for cld in all(clouds) do
		local x=cld.x local y=cld.y
		circfill(x+13,y+7,7,7)
		circfill(x+26,y+8,7,7)
		circfill(x+7,y+15,7,7)
		circfill(x+19,y+16,7,7)
		circfill(x+32,y+15,7,7)
	end
end
--outdoor scene
outdr_clouds={
	new_cloud(02,33),
	new_cloud(09,43),
	new_cloud(13,38), 
	new_cloud(20,34),
	new_cloud(24,45),
	new_cloud(31,36),
	new_cloud(36,42),
	new_cloud(45,44),
	new_cloud(48,34),
	new_cloud(55,40),
	new_cloud(62,37),
	new_cloud(69,43),
	new_cloud(72,33),
	new_cloud(80,39),
	new_cloud(88,42),
	new_cloud(95,34),
	new_cloud(97,40),
	new_cloud(105,36),
	new_cloud(111,44),
	new_cloud(118,33),
	new_cloud(125,42),
}
--home scene
home_clouds={
	new_cloud(-2,13,127),
	new_cloud(0,18,127),
	new_cloud(6,15,127),
	new_cloud(8,9,127),
	new_cloud(13,17,127),
}

--screen wipe
function do_wipe(n_frames,out,f)
	local t_len=n_frames
	local max_r=150
	for i=1,t_len do
		add(
			evnt_q,
			{
				f=function()
					local r=i/t_len*max_r
					local colur=0
					if (out) r=max_r-r
					circfill(p.x+4,p.y+4,r,0) 
				end,
				t=i
			}
		)
	end
	if f!=nil then
		add(evnt_q,{f=f,t=n_frames})
	end
end
function screen_wipe(fmid,fend)
	--todo: prevent input during
	--screen wipe
	local n_frms=64
	do_wipe(n_frms/2,false)
	add(
			evnt_q,
			{
				f=function()
					fmid()
					do_wipe(n_frms/2,true,fend)
				end,
				t=n_frms/2
			}
	)
end

--ui
ui_elms={
	id={
		shown=false,
		expired=true,
		f=function()
			local sx=cam_x+82
			local sy=cam_y+106
			local br={x=sx+43,y=sy+19}
			
			rectfill(sx,sy,br.x,br.y,15)
			line(br.x+1,sy,br.x+1,br.y,6)
			line(sx,br.y+1,br.x+1,br.y+1,6)
			spr(100,sx+2,sy+2)
			spr(116,sx+2,sy+10)
			print("M.OXLONG",sx+11,sy+1,0)
			local exp_txt="EXP:NO"
			if (ui_elms.id.expired) then
				exp_txt..="W"
			end
			print(exp_txt,sx+11,sy+7,0)
			print("SEX:YES",sx+11,sy+13,0)
		end,
	}
}

--map details
build_bkg={
	{--cream aprtmt interior
		x1=18*8,y1=52*8,x2=23*8,y2=61*8,
		clr=15
	},
	{--cream aprtmt interior
		x1=140,y1=160,x2=188,y2=236,
		clr=13
	},
	{--red brick tower interior
		x1=204,y1=60,x2=276,y2=236,
		clr=13
	},
	{--mall exterior
		x1=38*8,y1=45*8,x2=49*8,y2=61*8,
		clr=15
	},
	{--mall exterior2
		x1=49*8,y1=51*8,x2=59*8,y2=61*8,
		clr=15
	},
	{--mall interior
		x1=38*8,y1=13*8,x2=49*8,y2=29*8-1,
		clr=13
	},
	{--specsavers interior
		x1=50*8-4,y1=19*8,x2=59*8,y2=29*8-1,
		clr=13
	},
	{--bp exterior
		x1=640,y1=456,x2=703,y2=487,
		clr=11
	},
	{--bp interior
		x1=654,y1=200,x2=703,y2=231,
		clr=15
	},
	{--vtnz exterior
		x1=729,y1=424,x2=830,y2=487,
		clr=9
	},
	{--garage door border
		x1=94*8-1,y1=55*8-1,x2=99*8,y2=61*8-1,
		clr=4,
	},
	{--vtnz exterior garage black
		x1=94*8+1,y1=59*8,x2=99*8-1,y2=61*8-1,
		clr=0
	},
	{--vtnz interior lane
		x1=733,y1=176,x2=791,y2=231,
		clr=9
	},
	{--vtnz interior staffroom
		x1=800,y1=176,x2=826,y2=199,
		clr=13
	},
	{--vtnz interior office
		x1=792,y1=208,x2=826,y2=231,
		clr=3
	},
	{--vtnz office desk
		x1=808,y1=224,x2=824,y2=231,
		clr=9
	},
}

foreground={
 {--mall shadesail
		x1=38*8,y1=57*8-1,x2=50*8-1,y2=58*8-3,
		clr=1
	},
	{
		x=41*8+1,y=57*8,
		clr=7,
		text="mall"
	},
	{--specsavers shadesail
		x1=51*8,y1=57*8-1,x2=59*8-1,y2=58*8-3,
		clr=3
	},
	{
		x=51*8+1+12,y=57*8,
		clr=7,
		text="specsavers"
	},
	
	{
		x=91*8+3,y=53*8+1,
		clr=7,
		text="v.t.n.z."
	},
	{--vtnz door lft interior shdw
		x1=92*8,y1=59*8,x2=92*8,y2=61*8-1,
		clr=5
	},
}

function drw_details(details)
	for b in all(details)	do
		if (b.text!=nil) then
			print(b.text,b.x,b.y,b.clr)
		else
		rectfill(
			b.x1,b.y1,
			b.x2,b.y2, b.clr
		)
		end
	end
end

function draw_bus(x,y,flp)
	if flp then
		spr(86,x+8,y,2,3,flp)
		spr(87,x,y,1,2,flp)
		spr(119,x,y+16)
	else
		spr(86,x,y,2,3)
		spr(87,x+16,y,1,2,flp)
		spr(119,x+16,y+16)
	end
	local wx=x+8 local wy=y+16
	rect(wx+1,wy,wx+6,wy+7,0)
	rect(wx,wy+1,wx+7,wy+6,0)
	rectfill(wx+1,wy+2,wx+6,wy+5,6)
	rect(wx+2,wy+1,wx+5,wy+6,6)
	pset(wx+2,wy+3,7)
	pset(wx+4,wy+2,7)
	pset(wx+5,wy+4,7)
	pset(wx+3,wy+5,7)
end
function run_bus(
	x,y,flp,
	fmid,fend
)
	local len=32
	local disp=function(in_)
		for i=1,len do
			add(evnt_q,{
					f=function()
						local arg=(i/len)*24
						local ofst=24
						if flp then
							ofst*=-1 arg*=-1
						end
					 local tx=x+arg
					 if (in_) tx=x+ofst-arg
						draw_bus(tx,y,flp)
					end,
					t=i
			})
		end
	end
	disp(true)
	add(evnt_q,{	
		f=function() 
			disp() 
			if (fmid!=nil) fmid() 
		end,
		t=len
	})
	if fend!=nil then
		add(evnt_q,{f=fend,t=len*2})
	end
end

function draw_tree() 
	-- todo: draw tree at ducks
	-- home
end
-->8
--update
frame_count=0
function _update()
	frame_count+=1
	frame_count%=30
	
	upd_plr(p)
	
	prev_io={
		⬆️=btn(⬆️),
		⬇️=btn(⬇️),
		⬅️=btn(⬅️),
		➡️=btn(➡️),
		❎=btn(❎),
		🅾️=btn(🅾️),
	}
	
	for npc in all(npcs) do
		npc.cs=npc.idle_s
		if dlg_npc!=nil 
			and frame_count%15<10
			and dlg_npc.cs==
				dlg_npc.idle_s then
					dlg_npc.cs=dlg_npc.yap_s
		end
	end
	
	update_camera(p)
	
	if at_home(p) then
		upd_clouds(home_clouds)
	else
		upd_moving_elms()
		upd_clouds(outdr_clouds)
	end
end
-->8
--draw
function draw_spr(o)
	local flipx=o.dir=="⬅️"
	spr(o.cs,o.x,o.y,1,1,flipx)
end

function draw_plr(o)
	local flipx=o.dir=="⬅️"
	if (o.dx==0) then o.cs=1
	elseif frame_count%4==0	then
			o.cs=((o.cs)%count(o.s))+1
	end
	spr(o.s[o.cs],
		o.x,o.y,1,1,flipx)
	if has_backpack then
		spr(91,o.x,o.y,1,1,flipx)
	end
end

function draw_moving_elms()
	for i in pairs(moving_elms) do
		local elm=moving_elms[i]
		elm.draw(elm.x,elm.y)
	end
end

function draw_ui()
	for k,elm in pairs(ui_elms) do
		if (elm.shown) elm.f()
	end
end

function _draw() 
	cls()
	palt(0,false)
	palt(14,true)
	
	rectfill(--bluesky
		0,cam_y,
		cam_x+127,cam_y+127, 
		12
	)
	drw_details(build_bkg)
	map(0,0,0,0,128,128)
	drw_details(foreground)
	
	for npc in all(npcs) do
		draw_spr(npc)
	end
	
	if (show_plr) draw_plr(p)
	draw_moving_elms()
	if at_home(p) then
		draw_clouds(home_clouds)
	else
		draw_clouds(outdr_clouds)
	end
	
	draw_dialog()
	draw_ui()
	run_evnt_q()
end
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1eeeeeeee1eeeeeeeeeeeeeee66663333333b6666444444445555555555555555656666663b3333b344444444
eeeeeeeeeeeeeeeeee8888eee6fffffeeeeeee11eeeeeeee11eeeeeeeeeeeeee4643b113b113b644444444445444444556111115566666554433b44be5eeeeee
eeeeeeeeeeeeeeeee888888e66f5555feeeee114eeeeeeee411eeeeeeeeeeeee463b1113b1113b44444444445441414556111115666555663444433444444444
eeeeeeeee4eeee4ee888888e66f5555feeee1166eeeeeeee6611eeeeeeeeeeee63b11113b11113b64444444454114115561111155556666643444444e5eeeeee
eeeeeeee446ee444e555555e66f5555feee11446eee11eee44411eeeeeeeeeee43b11113b11113b6444444445411411556111115111111114444444444444444
eeeeeeee44444644e666666e66ffffffee116666ee1111ee666611eeeeeeeeee3b111113b111113b444444445411411556111115111111114544444466666666
eeeeeeee44464444e6eeee6e6ff77f8fe1144464e114411e4464411e111111113b111113b111113b44444444544444455611111511111111444445446eeeeeee
eeeeeeeee444444ee6eeee6ee565656e116444641164441144644411111111113b111113b111113b44444444546444455611111511111111444444446eeeeeee
eee55eeeeeeeee1144444444eee886eeee66666666666666666666eeeee65eee333333333333333beeeeee445444444556111115119999994444444444444444
11111111eeeeee1144444444ee87786ee4644644464446444644644eee6a65ee3b111113b111113beeeeee4454114115561111151199999944444454eeeeee5e
e555555eeeeeee11455ee554e8777786e4644644464446444644644ee6a0a65e3b111113b111113beeee44445411411556111115111111114444444444444444
e565656eeeeeee1145eeee54e8999c86ee66666666666666666666eee6a0a65e3b111113b111113beeee444454114115561111151111111144454444eeeeee5e
e565656ee11111114eeeeee4e8999986e4464446444644466444644e6aaaaa653b111113b111113bee4444445411411556111115111111114444444444444444
e565656eeeee5eee4eeeeee4e8577586ee66666666666666666666ee6aa0aa653b111113b111113bee4444445444444556111115111111114444444466666666
e565656eee55555e4eeeeee4ee87786ee4464464446444644464464e6aaaaa65333333333333333b4444444456666665566666656666666545444544eeeeeee6
e555555ee6e6e6e64eeeeee4eee886eee4464464446444644464464ee666665e55555555555555554444444455555555555555556666555644444444eeeeeee6
eeeeeeee6eeeee6e44444445eee776ee7777777677777776eeeeeeeee55ee55eeee66eeeeeeeeeeee4444445e556eeeee5555556e44fe44feeeeeee3eeeeeeee
ee6666eee6eee6ee445445eeeee776ee76c76c7676c76c76eeeeeeee77777777eeeaaeeee8e88e8ee4444445e556eeeee5555556e44fe44feeeeee3beeeeeeee
e6cccc6eee6e6eee4545445eeee776ee76c76c7678c76876eeeeeeeee777777eeeaaaaee88ee3e88e9e445e9e556eeeee5555556e44fe44feeeee3b3eeeeeeee
6cccccc6eee6eeee4545446eeee776ee7777777688878886eeeeeeeeeeeeeeeeeeaaaaeeee3e33eeeee445eee556eeeee555555644444444eeeeb444eeeeeeee
6cccccc6555555ee4545445eeee776ee76c76c7678376836eeeeeeeeeeeeeeeeeeeaaeeeeee33eeee4444445e556eeeee5555556e44fe44feee3434466115615
6cccccc67675555e454545eeeee776ee76c76c7676376c36eeeeeeeeeeeeeeeeeeeeeeeeee9999eee4444445e556eeeee5555556e44fe44fee34444456516611
e6cccc6e676555554555445eeee776ee777777764444445566666666eeeeeeeeeeeeeeeeee9999eee9e445e9e556eeeee5555556e44fe44feb33444411651156
ee6776ee767556654444446eeee776ee444444454444445566666666eeeeeeeeeeeeeeeeeee99eeeeee445eee556eeeee5555556e44fe44fb444444415665166
e777777e6765555544444444e55e555eefffffff66666666fffffffe4eeeeeeeeeeeeeeeeeeeeeeeeee445ee75576eeee5557756eeeeeeee3eeeeeee44444444
77777777767556654556655422222222666fffff65757576fffff6664666eeeeeeeeeeeeeeee88eeeee445eee556eeeee5555556eeeeeeee4beeeeee44444444
77777777555555554555555422222222666fffff6937ad46fffff6664666eeeeeeeeeeeeeeee8eeeeee445eee556eeeee555555655555555343eeeeee5ee5ee5
777776675835555e4444444426555562666fffff6937ad46fffff6664888888888888884e111815eeee445eee556eeeee5555556eeeeeeee44b3eeee5e55e55e
77777777444444444556655426666662efffffff6937ad46fffffffe488888888888888415518115eee445eee556eeeee5555556eeeeeeee444bbeeeeeeeeeee
77777777444444444555555426666662666fffff6937ad46fffff666466666666666666415511115eee445eee556eeeee5555556eeeeeeee444443eeeeeeeeee
7777777745eeee544444444426666662666fffff69e7ede6fffff666444444444444444415511115eee445eee556eeeee555555655555555444434beeeeeeeee
e777777e4eeeeee44eeeeee422222222666fffff0eeeeee0fffff6664eeeeee4eeeeeee415511115eee445eee556eeeee5555556eeeeeeee44444443eeeeeeee
5cc7777555555555eeeeeeee3333333555555eee777777751111111111111111eeeee0eeeee070eeeee070eeeee555eeeee555eeeeee777eeeee777eeeee777e
5cc7777551111115effffffe33333335504405ee7666675e1777777777777771eeee0e0eeee7aaaaeee7aaaaeee5056eeee5056eeeee707eeeee707eeeee707e
5c77777551111115f566f55f33333335566665ee75cc675e1111111111111111eeee0e0eeee7a999eee7aeeeee555566ee555566eeee77aaeeee77aaeeee77aa
5c77777551111115f566ffff333333355440445e7777775e1777777177777771eee66ee0ee77999eee779999ee55566eee5556ee7666777e7666777e7666777e
5c77777551111175f566f67f333333355666665e74cc66751111111111111111e88888e0e07797eee077999ee555eeeee555ee6e7766777e7766777e7766777e
5c7777c551111775f555f76f3333333554404405777777751777777777777771e88888e07707777e7707777e5555eeee5555eeeee777777ee777777ee777777e
5c7777c55c117775ffffffff333333355666666570116c751111111111111111e87778e0007777ee007777ee555eeeee555eeeeeeeaeeaeeeeaeeeaaeeaaeaee
5c7777c55cc77775e6eeee6e333333355555555577777775e6eeeeeeeeeeee6ee87778e0e799799ee799799e555eeeee555eeeeeeeaaeaaeeeaaeeeeeeeeeaae
ee3eee3e5c7777c5777777777703307765eee09655555555eeeeee8888888888e88888e05555555533333333eeeeeeeeeeee333eeeee333eeeee333eeeee333e
3ee3e3ee57777cc533333333303bb3036555e99656111115eeeee55555558555e85658e0666666663b111113ee44eeeeeeee303eeeee3038eeee303eeeee3034
e3e3e3ee5777ccc5bbbbbbbb03baab304444444456111115eeee577775758577e88888e0555555553b111113e444eeee3eee33883eee338eeeee3344eeee334e
ee3ee3e3577cccc5333333333ba77ab360e5e0e656111115eee5777557758577e888886e666666663b111113eee4eeee3333333e333333387566777e75667774
3e3e3e3e57ccccc5bbbbbbbb3ba77ab3655e533656177115eee5777577758577e88888ee555555553b111113eeee4eee73377733733777335666665e5666665e
e3e3ee3e5cccccc53333333303baab306555e11656711715ee57775777758577e55555ee666666663b111113eeee4eeee7777773e7777773e666655ee666655e
ee3333ee5cccccc577777777303bb3034444444457111175ee577757777585775666665e5555555555555555eeeeeeeeee77777eee77777eee4ee4eeee4ee4ee
eee33eee5555555577777777770330776eeeeee654444445ee577757777585775555555e6666666655555555eeeeeeeeee88e88eee88e88eee44e44eee44e44e
e4444446eeeeeeeeeeeeeeeeeeeeeeee7871181154888845ee5777577775857700000000000000000000000000000000eeee555eeeee555eeeee770eeeee770e
e4444446eeeeeeeeeeeeeeeeeeeeeeee8881111154444445e55775577775857700000000000000000000000000000000eeee505eeeee5057eeee077eeeee0778
ee44446eeeeeeeeeeeeeeeeeeeeeeeee7871818156111115e57775777775857700000000000000000000000000000000eeee5577eeee557eeeee7788eeee778e
ee44446eeeee888888888888eeeeeeee1111111156111115e577757777758577000000000000000000000000000000000565233e056523377666777e76667778
ee44446eeee88111781111788eeeeeee1111181156111115e577757777758577000000000000000000000000000000005665622e5665622e7766777e7766777e
ee44446eee8811771811771188eee5551111111156111115555555555555855500000000000000000000000000000000e656666ee656666ee777777ee777777e
ee44446ee881771118171111188e555eeeeeeeee56666665588885888888888800000000000000000000000000000000ee9ee9eeee9ee9eeee8ee8eeee8ee8ee
ee44446e8817111118711111118885eeeeeeeeee55555555555885888888888800000000000000000000000000000000ee99e99eee99e99eee88e88eee88e88e
ee88888888888888888888888888888e55555555eee76eee59758588888888880000000000000000eee040eeeee040eeeeeee08eeeeee088eeeeeeeeeeeeeeee
eaa880008888888888888888000888ae55777765eee76eee59588588888888880000000000000000eee44aaaeee44aaaeeeee088eeeee08eeeeeeeeeeeeeeeee
ea8800000888888888888880000088ae55707065eee76eee55888588888888880000000000000000eee4a999eee4a4eeee00001eee000018eeeeeeeeeeeeeeee
8880006000888888888888000600088e55777765eee76eee58888588888888880000000000000000ee4444eeee444999e000011ee000011eeeeeeeeeeeeeeeee
8880067600888888888888006760088559997765eee76eeee5885588888888880000000000000000e544544ee544544ee700111ee700111eeeee44eeeeee449e
e880006000888888888888000600088555777765eee76eeeee5555555555555500000000000000004444444e4444444e7e8ee8ee7e8ee8eeee44469eee4446ee
eeee00000eeeeeeeeeeeeee00000eeee57777776eee76eeeeeeeeeeeeeeeeeee0000000000000000544545ee544545eeee8ee8eeee8ee8eeeee666eeeee6669e
eeeee000eeeeeeeeeeeeeeee000eeeee57777776eee76eeeeeeeeeeeeeeeeeee0000000000000000e499499ee499499eee88e88eee88e88eeeee4eeeeeee4eee
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000707070707070707070700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000415151515151515151610000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000418090518090518090610000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000041a591518191518191610000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000415151515151515151610000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000418090518090518090610000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000041819151a591518191610000626262626262626262626262620000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000415151515151515151610000430000000000000000000000630000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000418090518090518090610000431414001414001414001414630000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000041819151819151a591610000431515001515001515001515630000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000415151515151515151610000430000000000000000000000630000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000418090518090518090610000431414001414001414001414630000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000041819151a591518191610000431515001515001515001515636262626262626262626200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000006262626262626200415151515151515151610000430000000000000000000000000000000000000000006300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000050000000004300000000006300418090518090518090610000431414001414001414001414000014140014140014146300000000
00000000000000000000000000000000000000000000000000000062626262626262626262626262000000000000000000000000000000000000000000000000
0000000000000000000000405160000000434200520042630041a591518191518191610000431515001515001515001515000015150015150015156300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000406000000000
00000000000000000000405151516000004300000000006300415151515151515151610000430000000000000000000000000000000000000000006300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040515160000000
00000000000000000040515151515160004342004200526300418090518090518090610000431414001414001414001414000014140014140014146300000000
00000000000000000000000000000000000000000000000000000000140095959595950000141400000000000000000000000000000000004051424251600000
00000000000000000041809051809061004300000000006300418191518191518191610000431515001515001515001515000015150015150015156300000000
00000000000000000000000000000025252535252525252525000000150095959595950000151500000000000000000000000000000000405151515151516000
00000000000000000041819151819161004352004200426300415151515151515151610000436262626262626262626262620062626262626262626300000000
00000000000000000000000000000000320000620000003234000000000095959595950000141400000000000000000000000000000000414242515142426100
00310000000000000041515151515161004300000000006300418090515151518090610000433214141414141414141414320032141414141414326300000000
00000000000000000000000000000000320000710000003234000000000095959595950000151500000000000000000000000000000000415151515151516100
0032000000000000004181b051818161004342b0420052630041819151c0c051819161000043320404040404c0c004040432c232c0c004040404326300000000
00000000000000000000000000000000328184818481c03234030000550000000000000000001626360000000000000000000000009300415242514242b06100
0032f0f100010000004151b151515161014300b1000000630041515151c1c151515161000043321515151515c1c115151532c332c1c115151515326300000000
00000000000000000000000000000000320085008500c1323403000056000000000000000007172737000000000000000000000000d2d2415151515151b16100
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1
e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1
e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1
__gff__
0001010005090609000003004003030100010300838383000000000040030301000003000009090000000303000005010001030083008300000100030009060400000083000003030000000000000000000003030000000000000900000000000009010900000000000000000000000003030003008403030000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000007070707070707070707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000014151515151515151516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001400002b032707270375000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001400003b321023031275000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000153f000a0a0a0a0a0a16000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001400002b002700030075000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001400003b000200221175000026262626262626262626262626000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000015003f0a0a0a0a0a0a16000034000000000000000000000036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001400002b002700030075000034000000000000000000000036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001400003b000200221175000034000000000000000000000036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000143f000a0a0a0a0a0a16000034000000000000000000000036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000001400002c202700272175000034003f0a0a0a0a0a0a0a0a0a36000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001e00000000000000001400003c303202023175000034000023270027002700270036262626262626262626260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001e262626262626260014003f0a0a0a0a0a0a1600003400002854422000305403002b000000003000302020360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001e34032428242036001400002b00270027007500003400000246473233305436023b002211113002303232360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001e34223738073236001400003b0202120202750000343f000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a36000000000000000000000000000000000000000000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a000000000000000000000000000000000000040600000000
000000000000000000000000000000001e340a0a0a0a0a3600143f000a0a0a0a0a0a1600003400005454275435540027000a000a0027000a002700360000000000000000000000000000000000000000000000000000000000000075002300000023000a00280075000000000000000000000000000000000004151506000000
00000000000000000000002a3d3d3d3d1e34292428241a36001400002b00270003007500003400003535413535540003000a002c0042002b004200360000000000000000000000000000000000000000000000000000000000000075002300000023000a00004275000000000000000000000000000000000415242415060000
00000000000000000000003a000000001e343033121a0a36001400003b00020022117500003400003535513535540036020a003c0212113b021211360000000000000000000000000000000000000052525253525252525252000075002800000028000a0202300a00000000000000000000000000000004150024242b150600
030000000021000000000023000000001e340a0a0a0a0a360014003f0a0a0a0a0a0a16000034003f0a0a0a0a0a0a0a0a0a0a000a0a0a0a0a0a0a0a360000000000000000000000000000000000000000234300270707270743000075000000000026260a0a0a0a0a00000000000000000000000000000014220001323b101600
12110001003100000039003a000000131e34282400242836001400002700002700007500003400000000000000000000000a002700270027002700360000000000000000000000000000000000000000234300005454005443000075000000000017000a28002875000000000000000000000000000000140a0a0a0a0a0a1600
0e0e0e0e0e0e0e3e0075003a000000231e34002421241a3600140000000c0c000000750000340000500000500c0c5000000a00500c0c45200000003600000000000000000000000000000000000000002343440054540c54430000750c0000000048002c000707750000000000000000000000000039001424282129420b1600
1e1e1e1e1e1e1e1e0e0e3e3a000f1f231e343707311a323600143f00101c1c002211160000343f00600000601c1c6000100a3f601c1c45450045023600000000000000000000000000000000000000002343220243541c54430000751c0033464758003c0000000a000000000000000000000000002d2d1437003133321b1600
1e1e1e1e1e1e1e1e1e1e1e0e0e0e0e0e0e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e
__sfx__
001000001505015050170501a0501c0001c0501f05021050210001f0501c0501a050180501a0501c0501d0001a0501a0501a0501c0501c0501c05018050180501805026000180502d00018050180000000000000
0000000011110161201a1201c1201f1202112022120201201a120131200e120091200512003120011300010000100001000010000100021000110000100081000610005100041000310003100031000310003100
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
112000001005015055150551505517050180551805518055150501305513055130551005013055000000000010050150551505515055170501805518055180551a0501c0551c0551c055180501c0550000000000
012000001c050210552105521055210501c0551c0551c0551c0501805518055180551805015050000000000015050110551105511055110551805518055180551805500000000001800518055180551505515055
30200000070551505500000150550000015055000001505500000090550000009055000001c0551c0551c055210052d057210572d057210572d057210572d0570000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001505015050170501a0501c0001c0501f05021050210001f0501c0501a050180501a0501c0501d0001805018050180501c0501c0501c0501f0501f0501f05026000180502d00018050180000000000000
001000001505015050170501a0501c0001c0501f05021050210001f0501c0501a050180501a0501c0501d0001a0501c0501f0501c0501a0501c0501c0501d0501c05026000180502d00018050180000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001895000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 000e4344
01 03444344
01 044f4344
04 054f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344
00 4e4f4344

