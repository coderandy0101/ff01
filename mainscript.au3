#Region Configuration
	Local Const $version = "1.1"
	Local Const $pickupall = True
#EndRegion
#Region Build
	Local Const $skillbartemplate_player = "OgcTcZ885RgNB1ZHQWZoT48cAA"
	Local Const $skill_return = [1, 15, 770]
	Local Const $skill_serpent = [2, 5, 456]
	Local Const $skill_shadowform = [3, 5, 826]
	Local Const $skill_shroud = [4, 10, 1031]
	Local Const $skill_storm = [5, 5, 1474]
	Local Const $skill_soh = [6, 5, 929]
	Local Const $skill_whirling = [7, 10, 450]
	Local Const $skill_winnowing = [8, 5, 463]
#EndRegion
#Region Variables
	Global $xs_n
	Local $dyetosell
	Local $nbruns = 0
	Local $nbfails = 0
	Local $brunning = False
	Local $binitialized = False
	Local $bresignrdy = False
#EndRegion
#Region Constants
	Local Const $mapid_anjeka = 349
	Local Const $mapid_drazach = 195
	Local Const $modeid_breambelrecurve = 934
	Local Const $modeid_breambellong = 868
	Local Const $modeid_breambelshort = 957
	Local Const $modeid_breambelflat = 904
	Local Const $modeid_breambelhorn = 906
	Local Const $modelid_echovald = 945
	Local Const $modelid_gothic = 951
	Local Const $modelid_amber = 940
	Local Const $modelid_ornate = 954
	Local Const $modelid_dragonmoss = 3718
	Local Const $modelid_dragonroots = 819
#EndRegion
#Region GUI
	Opt("GUIOnEventMode", 1)
	Local Const $maingui = GUICreate("Dragon Moss" & $version, 309, 175)
	Local Const $gsettings = GUICtrlCreateGroup("Settings", 5, 2, 135, 80)
	Local Const $lblname = GUICtrlCreateLabel("Character :", 6, 18, 129, 15, $ss_center)
	Local $txtname = GUICtrlCreateCombo("", 8, 35, 129, 25, BitOR($cbs_dropdown, $cbs_autohscroll))
	GUICtrlSetData(-1, getloggedcharnames(), $mfirstchar)
	Local Const $cbdisablegraphics = GUICtrlCreateCheckbox("Disable Graphics", 10, 60, 97, 17)
	Local Const $lbllog = GUICtrlCreateEdit("", 142, 5, 162, 165, BitOR($es_autovscroll, $es_readonly, $es_wantreturn, $ws_vscroll), 0)
	Local Const $gstats = GUICtrlCreateGroup("Stats", 5, 85, 135, 55)
	Local Const $lblsuccruns = GUICtrlCreateLabel("Success Runs :", 10, 102, 75, 17)
	Local Const $stsuccruns = GUICtrlCreateLabel("0", 90, 102, 49, 17, $ss_center)
	Local Const $lblfailruns = GUICtrlCreateLabel("Fail Runs : ", 10, 120, 75, 17)
	Local Const $stfailruns = GUICtrlCreateLabel("0", 90, 120, 49, 17, $ss_center)
	Local Const $btstart = GUICtrlCreateButton("Start", 4, 145, 67, 25, $bs_vcenter)
	Local Const $bexit = GUICtrlCreateButton("Exit", 74, 145, 67, 25, $bs_vcenter)
	GUISetOnEvent($gui_event_close, "EventHandler")
	GUICtrlSetOnEvent($cbdisablegraphics, "EventHandler")
	GUICtrlSetOnEvent($btstart, "EventHandler")
	GUICtrlSetOnEvent($bexit, "EventHandler")
	TraySetIcon("icon.ico")
	GUISetIcon("icon.ico")
	GUISetState(@SW_SHOW)
#EndRegion
#Region Loops
	Do
		Sleep(100)
	Until $binitialized
	initpacket()
	While 1
		If $brunning Then
			manageinventory()
			If getmapid() <> $mapid_anjeka Then
				travelto($mapid_anjeka)
				$bresignrdy = False
			EndIf
			If NOT $bresignrdy Then
				getresignready()
			EndIf
			If dojob() Then
				$nbruns += 1
				GUICtrlSetData($stsuccruns, $nbruns)
			Else
				$nbfails += 1
				GUICtrlSetData($stfailruns, $nbfails)
			EndIf
			If NOT $brunning Then _travelgh()
			If Mod($nbruns, 20) = 0 AND NOT $mrendering Then _purgehook()
		EndIf
		Sleep(250)
	WEnd

	Func eventhandler()
		Switch @GUI_CtrlId
			Case $gui_event_close
				If NOT $mrendering Then togglerendering()
				Exit
			Case $bexit
				If NOT $mrendering Then togglerendering()
				Exit
			Case $btstart
				If $brunning Then
					GUICtrlSetData($btstart, "Resume")
					$brunning = False
				ElseIf $binitialized Then
					GUICtrlSetData($btstart, "Pause")
					$brunning = True
				Else
					$brunning = True
					GUICtrlSetData($btstart, "Initializing...")
					GUICtrlSetState($btstart, $gui_disable)
					GUICtrlSetState($txtname, $gui_disable)
					WinSetTitle($maingui, "", GUICtrlRead($txtname))
					TraySetToolTip(GUICtrlRead($txtname))
					If GUICtrlRead($txtname) = "" Then
						If initialize(ProcessExists("gw.exe"), True, True, False) = False Then
							MsgBox(0, "Error", "Guild Wars it not running.")
							Exit
						EndIf
					Else
						If initialize(GUICtrlRead($txtname), True, True, False) = False Then
							MsgBox(0, "Error", "Can't find a Guild Wars client with that character name.")
							Exit
						EndIf
					EndIf
					GUICtrlSetData($btstart, "Pause")
					GUICtrlSetState($btstart, $gui_enable)
					$binitialized = True
				EndIf
			Case $cbdisablegraphics
				togglerendering()
		EndSwitch
	EndFunc

#EndRegion

Func getresignready()
	LoadSkillTemplate("OgcTcZ885RgNB1ZHQWZoT48cAA")
	out("Preparing resign")
	move(-11209, -23100)
	waitmaploading($mapid_drazach, 45000)
	move(-11229, 20150)
	waitmaploading($mapid_anjeka, 45000)
	switchmode(1)
	$bresignrdy = True
EndFunc

Func dojob()
	Local $ldeadlock
	out("Going outside")
	move(-11209, -23100)
	waitmaploading($mapid_drazach)
	If getmapid() <> $mapid_drazach Then Return False
	initpointers()
	targetnearestally()
	Sleep(50)
	useskill(2, -2)
	_useskillex($skill_return[0], -1, 8000)
	moveto(-7924, 18281)
	useskill($skill_serpent[0], $myptr)
	_useskillex($skill_shadowform[0])
	_useskillex($skill_shroud[0])


	out("Balling dragons")
	moveto(-7086, 17979)
	_useskillex($skill_storm[0])
	moveto(-6153, 16621)
	moveto(-5404, 15538)
	moveto(-6111, 17160, 5)
	out("SoH")
	useskill($skill_soh[0], $myptr)
	moveto(-6604, 18585, 5)
	useskillex($skill_winnowing[0])
	Do
	Sleep(250)
	Until GetSkillbarSkillRecharge(3) = 0
	useskillex($skill_shadowform[0])
	Out("Killing.")
	Sleep(250)
	If NOT getisdead($myptr) Then out("Killing")
	useskill($skill_whirling[0], $myptr)

	$ldeadlock = TimerInit()
	Do
		Sleep(500)
	Until getnumberoffoesinrangeofagent($myptr, $range_adjacent, $modelid_dragonmoss) = 0 OR getisdead($myptr) OR TimerDiff($ldeadlock) > 20000
	rndsleep(250)
	_pickuploot()
	If getisdead($myptr) Then
		out("Failed")
		resigntooutpost(True)
		Return False
	Else
		resigntooutpost(False)
		Return True
	EndIf
EndFunc

#Region CastEngine

	Func _useskillex($askillslot, $atarget = $myptr, $atimeout = 3000, $askillbarptr = $skillbar)
		Local $lskillptr = getskillptr(getskillbarskillid($askillslot, 0, $askillbarptr))
		Local $laftercast = memoryread($lskillptr + 64, "float") * 1000
		useskill($askillslot, $atarget)
		Local $ltimer = TimerInit()
		Do
			Sleep(50)
			If getisdead($myptr) Then Return
		Until getskillbarskillrecharge($askillslot, 0, $askillbarptr) <> 0 OR TimerDiff($ltimer) > $atimeout
	EndFunc

#EndRegion
#Region PickUp

	Func _pickuploot($aminslots = 2)
		Local $lmex, $lmey, $lagentx, $lagenty
		Local $lslots = countslots()
		Local $lagentarray = memoryreadagentptrstruct(1, 1024)
		For $i = 1 To $lagentarray[0]
			If getisdead($myptr) Then Return False
			$lagentid = memoryread($lagentarray[$i] + 44, "long")
			$litemptr = getitemptrbyagentid($lagentid)
			If $litemptr = 0 Then ContinueLoop
			$litemtype = memoryread($litemptr + 32, "byte")
			If $lslots < $aminslots Then
				If $litemtype <> 11 AND $litemtype <> 20 Then ContinueLoop
			EndIf
			If NOT canpickup($litemptr) Then ContinueLoop
			updateagentposbyptr($myptr, $lmex, $lmey)
			updateagentposbyptr($lagentarray[$i], $lagentx, $lagenty)
			$ldistance = Sqrt(($lmex - $lagentx) ^ 2 + ($lmey - $lagenty) ^ 2)
			If $ldistance > 2000 Then ContinueLoop
			pickupitems($lagentarray[$i], $lagentid, $lagentx, $lagenty, $ldistance, $myptr)
		Next
	EndFunc

	Func canpickup($aitemptr)
		Local $lmodelid = memoryread($aitemptr + 44, "long")
		Local $litemtype = memoryread($aitemptr + 32, "byte")
		If $litemtype = 20 Then Return True
		If $pickupall Then
			If $lmodelid = 146 Then
				$extra = memoryread($aitemptr + 34, "short")
				If $extra = 10 OR $extra = 12 Then Return True
				Return False
			EndIf
			If $lmodelid = 21799 Then Return False
			Return True
		EndIf
		Switch $lmodelid
			Case $modelid_dragonroots
				Return True
			Case $modeid_breambellong, $modeid_breambelrecurve, $modeid_breambelshort, $modeid_breambelflat, $modeid_breambelhorn
				Return True
			Case 22751
				Return True
			Case 146
				$extra = memoryread($litemptr + 34, "short")
				If $extra = 10 OR $extra = 12 Then Return True
			Case $modelid_amber, $modelid_echovald, $modelid_gothic, $modelid_ornate
				If getrarity($aitemptr) = $rarity_gold Then Return True
		EndSwitch
		Return False
	EndFunc

#EndRegion
#Region Inventory

	Func manageinventory()
		LoadSkilltemplate("OgcTcZ885RgNB1ZHQWZoT48cAA")
		Local $lmapid_hall
		out("Checking Inventory")
		If getgoldcharacter() > 90000 Then depositgold()
		If countslots() < 5 Then
			_travelgh()
			$lmapid_hall = getmapid()
			gotonpc(getplayerptrbyplayernumber(getmerchant($lmapid_hall)))
			_inventory()
		EndIf
	EndFunc

	Func _inventory()
		_identify()
		_sell()
		_salvage()
		_store()
		depositgold()
		Sleep(getping() + 500)
	EndFunc

	Func _identify()
		Local $lbag, $litem
		For $j = 1 To 4
			out("Identifying bag " & $j)
			$lbag = getbagptr($j)
			For $i = 1 To memoryread($lbag + 32, "long")
				idkit()
				$litem = getitemptrbyslot($lbag, $i)
				If NOT memoryread($litem) Then ContinueLoop
				If getisunided($litem) Then
					identifyitem($litem)
				EndIf
				Sleep(getping() * 3)
			Next
		Next
	EndFunc

	Func _salvage()
		Local $lquantityold, $loldvalue
		salvagekit()
		Local $lsalvagekitid = findsalvagekit(1, 4)
		Local $lsalvagekitptr = getitemptr($lsalvagekitid)
		For $bag = 1 To 4
			$lbagptr = getbagptr($bag)
			If $lbagptr = 0 Then ContinueLoop
			For $slot = 1 To memoryread($lbagptr + 32, "long")
				$litem = getitemptrbyslot($lbagptr, $slot)
				If NOT getcansalvage($litem) Then ContinueLoop
				out("Salvaging : " & $bag & "," & $slot)
				$lquantity = memoryread($litem + 75, "byte")
				$itemmid = memoryread($litem + 44, "long")
				$itemrarity = getrarity($litem)
				If $itemrarity = $rarity_white OR $itemrarity = $rarity_blue Then
					For $i = 1 To $lquantity
						If memoryread($lsalvagekitptr + 12, "ptr") = 0 Then
							salvagekit()
							$lsalvagekitid = findsalvagekit(1, 4)
							$lsalvagekitptr = getitemptr($lsalvagekitid)
						EndIf
						$lquantityold = $lquantity
						$loldvalue = memoryread($lsalvagekitptr + 36, "short")
						startsalvage($litem, $lsalvagekitid)
						Local $ldeadlock = TimerInit()
						Do
							Sleep(200)
						Until memoryread($lsalvagekitptr + 36, "short") <> $loldvalue OR TimerDiff($ldeadlock) > 5000
					Next
				ElseIf $itemrarity = $rarity_purple OR $itemrarity = $rarity_gold Then
					$itemtype = memoryread($litem + 32, "byte")
					If $itemtype = 0 Then
						ContinueLoop
					EndIf
					If memoryread($litem + 12, "ptr") <> 0 Then
						If memoryread($lsalvagekitptr + 12, "ptr") = 0 Then
							salvagekit()
							$lsalvagekitid = findsalvagekit(1, 4)
							$lsalvagekitptr = getitemptr($lsalvagekitid)
						EndIf
						$loldvalue = memoryread($lsalvagekitptr + 36, "short")
						startsalvage($litem, $lsalvagekitid)
						Sleep(500 + getping())
						salvagematerials()
						Local $ldeadlock = TimerInit()
						Do
							Sleep(200)
						Until memoryread($lsalvagekitptr + 36, "short") <> $loldvalue OR TimerDiff($ldeadlock) > 5000
					EndIf
				EndIf
			Next
		Next
		salvagekit()
	EndFunc

	Func getcansalvage($aitemptr)
		If memoryread($aitemptr + 24, "ptr") <> 0 Then Return False
		Local $litemtype = memoryread($aitemptr + 32, "byte")
		If $litemtype <> 5 Then Return False
		Local $lmodelid = memoryread($aitemptr + 44, "long")
		Switch $lmodelid
			Case $modeid_breambellong, $modeid_breambelrecurve, $modeid_breambelshort, $modeid_breambelflat, $modeid_breambelhorn
				Return True
		EndSwitch
		Return False
	EndFunc

	Func _sell()
		Local $lbag, $litem, $lmod
		out("Selling")
		For $j = 1 To 4
			$lbag = getbagptr($j)
			For $i = 1 To memoryread($lbag + 32, "long")
				$litem = getitemptrbyslot($lbag, $i)
				If $litem == 0 Then ContinueLoop
				If memoryread($litem + 24, "ptr") <> 0 Then ContinueLoop
				If memoryread($litem + 36, "short") <= 0 Then ContinueLoop
				If memoryread($litem + 76, "byte") <> 0 Then ContinueLoop
				Switch getrarity($litem)
					Case 2621
					Case 2623, 2624, 2626
						If NOT getisided($litem) Then ContinueLoop
					Case Else
						ContinueLoop
				EndSwitch
				Switch memoryread($litem + 32, "byte")
					Case 5
						Local $lmodelid = memoryread($litem + 44, "long")
						If $lmodelid = $modeid_breambelrecurve OR $lmodelid = $modeid_breambellong OR $lmodelid = $modeid_breambelshort OR $lmodelid = $modeid_breambelflat OR $lmodelid = $modeid_breambelhorn Then ContinueLoop
					Case 24
						Local $lmod = getdualmodshield($litem)
						If $lmod <> False Then
							Local $lmodelid = memoryread($litem + 44, "long")
							Local $larr[] = [$lmodelid, getitemreq($litem), $lmod]
							sendsafepacket(prepare("drop", $larr))
						EndIf
						If getrarity($litem) = $rarity_gold AND memoryread($litem + 20, "long") = 5 Then ContinueLoop
					Case 10
						Switch memoryread($litem + 34, "short")
							Case 10, 12
								ContinueLoop
							Case Else
						EndSwitch
					Case 18
						ContinueLoop
					Case 11
						If memoryread($litem + 44, "long") = 934 Then ContinueLoop
					Case 29
						ContinueLoop
					Case 30
						ContinueLoop
					Case Else
				EndSwitch
				sellitem($litem)
				Sleep(getping() + 500)
			Next
		Next
	EndFunc

	Func _store()
		Local $lbag, $litem, $lslot, $litemtype
		For $j = 1 To 4
			out("Storing bag " & $j)
			$lbag = getbagptr($j)
			If ischestfull() Then Return
			For $i = 1 To memoryread($lbag + 32, "long")
				$litem = getitemptrbyslot($lbag, $i)
				If $litem = 0 Then ContinueLoop
				$litemtype = memoryread($litem + 32, "byte")
				Switch $litemtype
					Case 11, 30
						If memoryread($litem + 75, "byte") <> 250 Then ContinueLoop
					Case 24
					Case Else
						ContinueLoop
				EndSwitch
				$lslot = openstorageslot()
				If IsArray($lslot) Then
					moveitem($litem, $lslot[0], $lslot[1])
					Sleep(getping() + Random(500, 750, 1))
				EndIf
			Next
		Next
	EndFunc

	Func idkit()
		If findidkit(1, 4) = 0 Then
			out("ID kit")
			If getgoldcharacter() < 100 Then
				out("Golds")
				withdrawgold(100)
				rndsleep(1000)
			EndIf
			buyitem(5, 1, 100)
			rndsleep(1000)
		EndIf
	EndFunc

	Func salvagekit()
		If findsalvagekit(1, 4) = 0 Then
			out("Salvage kit")
			If getgoldcharacter() < 100 Then
				out("Golds")
				withdrawgold(100)
				rndsleep(1000)
			EndIf
			buyitem(2, 1, 100)
			rndsleep(1000)
		EndIf
	EndFunc

	Func ischestfull()
		If countslotschest() = 0 Then
			out("Chest Full")
			Return True
		EndIf
		Return False
	EndFunc

#EndRegion
#Region Travel

	Func _travelgh()
		Local $larray_gh[16] = [4, 5, 6, 52, 176, 177, 178, 179, 275, 276, 359, 360, 529, 530, 537, 538]
		Local $lmapid = getmapid()
		If _arraysearch($larray_gh, $lmapid) <> -1 Then Return
		travelgh()
	EndFunc

	Func resigntooutpost($aisdead)
		out("Resigning")
		resign()
		Do
			Sleep(100)
		Until getisdead($myptr)
		If $aisdead Then
			rndsleep(4000)
		Else
			rndsleep(1500)
		EndIf
		returntooutpost()
		waitmaploading($mapid_anjeka)
	EndFunc

#EndRegion
#Region GUI Functions

	Func out($astring)
		Local $lstringlen = StringLen($astring)
		Local $leditlen = _guictrledit_gettextlen($lbllog)
		Local $timestamp = "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] "
		If $lstringlen + $leditlen > 30000 Then
			GUICtrlSetData($lbllog, StringRight(_guictrledit_gettext($lbllog), 30000 - $lstringlen - 1000))
		EndIf
		_guictrledit_appendtext($lbllog, @CRLF & $timestamp & $astring)
		_guictrledit_scroll($lbllog, 1)
	EndFunc

	Func getchecked($guictrl)
		Return (GUICtrlRead($guictrl) == $gui_checked)
	EndFunc

#EndRegion GUI Functions

Func getdualmodshield($aitem)
	Local $lhp, $lhpench, $lhpstan
	Local $lredench, $lredstance, $lredhexed, $lreddam
	Local $larmorvs, $larmort
	$lhp = getmodbyidentifier($aitem, "4823")[1]
	$lhpench = getmodbyidentifier($aitem, "6823")[1]
	$lredench = getmodbyidentifier($aitem, "8820")[0]
	$lreddam = getmodbyidentifier($aitem, "7820")[1]
	$larmorvs = getmodbyidentifier($aitem, "4821")[0]
	$larmort = getmodbyidentifier($aitem, "4821")[1]
	If $larmort = 8 AND $larmorvs = 10 Then
		If $lhp = 30 Then
			Return "+10 Demons/+30"
		EndIf
		If $lhpench = 45 Then
			Return "+10 Demons/+45^e"
		EndIf
		If $lredench = 2 Then
			Return "+10 Demons/-2^e"
		EndIf
	EndIf
	If $lhp = 30 Then
		If $lreddam = 20 Then
			Return "+30/-5"
		EndIf
	EndIf
	Return False
EndFunc
