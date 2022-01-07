B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11
@EndOfDesignText@
Sub Class_Globals
	'Structure - map of header to list of line
	Public mapOne As Map '{headerid: [lineid#1, lineid#2, lineid#3, ...]}
	'Contents - map of header to its content
	Public mapHeader As Map 'ignore '{headerid: {text: text1}}
	'Summary - map of header to its sum
	Public mapSum As Map '{headerid: sum}
	'Summary - map of header of its count
	Public mapCount As Map '{headerid: count}	
	'Contents - map of line to its content
	Public mapLine As Map 'ignore '{lineid: [{text: text1, qty: qty1}, {text: text2, qty: qty2}, {text: text3, qty: qty3}, ...]}
	'Hide or Show
	Public mapShow As Map 
	'Event and callback
	Private m_callback As Object
	Private m_event As String
	'Temporary index of UI
	Private m_uiindex As Int
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(callback As Object, event As String)
	mapOne.Initialize
	mapHeader.Initialize
	mapLine.Initialize
	mapShow.Initialize
	mapSum.Initialize
	mapCount.Initialize
	m_callback = callback
	m_event = event
	m_uiindex = -1
End Sub

Public Sub setUIIndex(idx As Int) 
	m_uiindex = idx
End Sub

Public Sub getSize() As Int
	Return mapOne.Size
End Sub

Public Sub ClearAll()
	If mapOne.IsInitialized Then
		mapOne.Clear
	End If
	If mapHeader.IsInitialized Then
		mapHeader.Clear
	End If
	If mapLine.IsInitialized Then
		mapLine.Clear
	End If
	If mapSum.IsInitialized Then
		mapSum.clear
	End If
	If mapCount.IsInitialized Then
		mapCount.clear
	End If
	If mapShow.IsInitialized Then
		mapShow.Clear
	End If
End Sub

Public Sub getContent(i_value As String) As String
	If i_value = "" Then
		Return ""
	End If
	Dim arr() As String = Regex.Split("\_", i_value)
	If arr.Length = 2 Then 'Head
		'Type conversion
		Dim headid As Int = arr(1)
		If mapHeader.ContainsKey(headid) = False Then
			Return ""
		End If
		Dim innermap As Map = mapHeader.Get(headid)
		Return innermap.Get("text")
	End If
	If arr.Length = 3 Then 'Line
		'Type conversion		
		Dim lineid As Int = arr(2)
		If mapLine.ContainsKey(lineid) = False Then
			Return ""
		End If
		Dim innermap As Map = mapLine.Get(lineid)
		Return innermap.Get("item") & "^" & innermap.Get("qty")
	End If
	Return ""
End Sub

Public Sub isHeadExpanded(i_headid As Int) As Boolean
	If mapShow.IsInitialized = False Then
		Return False
	End If
	If mapShow.ContainsKey(i_headid) = False Then
		Return False
	End If
	If 1 = mapShow.Get(i_headid) Then
		Return True
	End If
	Return False
End Sub

Public Sub expandHead(i_headid As Int, i_ui As Int) As Boolean
	If mapShow.IsInitialized = False Or mapOne.IsInitialized = False Then
		Return False
	End If
	If mapShow.ContainsKey(i_headid) = False Or mapOne.ContainsKey(i_headid) = False Then
		Return False
	End If	
	If SubExists(m_callback, m_event) Then
		mapShow.Put(i_headid, 1)
		Dim lstLine As List = mapOne.Get(i_headid)
		CallSubDelayed2(m_callback, m_event, _ 
			CreateMap("action": "expanded", "uiindex": i_ui, "headid": i_headid, "count": lstLine.size))
	End If
	Return True
End Sub

Public Sub collapseHead(i_headid As Int, i_ui As Int) As Boolean
	If mapShow.IsInitialized = False Or mapOne.IsInitialized = False Then
		Return False
	End If
	If mapShow.ContainsKey(i_headid) = False Or mapOne.ContainsKey(i_headid) = False Then
		Return False
	End If	
	If SubExists(m_callback, m_event) Then
		mapShow.Put(i_headid, 0)
		Dim lstLine As List = mapOne.Get(i_headid)
		CallSubDelayed2(m_callback, m_event, _ 
			CreateMap("action": "collapsed", "uiindex": i_ui, "headid": i_headid, "count": lstLine.size))
	End If
	Return True
End Sub

Public Sub exchangeLine(i_oheadid As Int, i_headText As String, i_lineid As Int, i_ui As Int) As Boolean
	If mapOne.IsInitialized = False Then
		Return False
	End If
	If mapOne.ContainsKey(i_oheadid) = False Then
		Return False
	End If
	Dim isHeadCreated As Boolean = False
	Dim isHeadDeleted As Boolean = False
	Dim isTargetShown As Boolean = True
	' Target
	Dim headid As Int = getHeadIdByText(i_headText)
	If headid = -1 Then
		' Create New head
		isHeadCreated = True		
		Dim maxheadkey As Int = getMaxKeyInMap(mapHeader)
		headid = maxheadkey + 1
		mapHeader.Put(headid, CreateMap("text": i_headText))		
		mapShow.Put(headid, 1)
		Dim lst As List : lst.Initialize
		lst.Add(i_lineid)
		mapOne.Put(headid, lst)
		mapSum.Put(headid, getHeaderSum(headid))
		mapCount.Put(headid, 1)
		isTargetShown = True
'		targetcount = 1
	Else
		isHeadCreated = False
		Dim lstTarget As List = mapOne.Get(headid)
		If lstTarget.IsInitialized = False Then
			Return False
		End If
		If 0 = mapShow.Get(headid) Then
			isTargetShown = False 
		Else
			isTargetShown = True
		End If
		lstTarget.Add(i_lineid)
		mapSum.Put(headid, getHeaderSum(headid))
		mapCount.Put(headid, getHeaderCount(headid))
	End If
	' Source
	Dim lstSource As List = mapOne.Get(i_oheadid)	
	If lstSource.IsInitialized = False Then
		Return False
	End If
	Dim foundidx As Int = lstSource.IndexOf(i_lineid)
	If foundidx = -1 Then
		Return False
	End If
	If lstSource.Size = 1 Then
		' Delete Old head
		isHeadDeleted = True
		mapHeader.Remove(i_oheadid)
		mapShow.Remove(i_oheadid)
		mapOne.Remove(i_oheadid)
		mapSum.Remove(i_oheadid)
		mapCount.Remove(i_oheadid)
	Else
		isHeadDeleted = False
		lstSource.RemoveAt(foundidx)
		mapSum.Put(i_oheadid, getHeaderSum(i_oheadid))
		mapCount.Put(i_oheadid, getHeaderCount(i_oheadid))
	End If		
	'lstTarget.Add(i_lineid)
	If SubExists(m_callback, m_event) Then		
		CallSubDelayed2(m_callback, m_event, _ 
			CreateMap("action": "exchanged", _ 
				"isheadcreated": isHeadCreated, "isheaddeleted": isHeadDeleted, _ 
				"istargetshown": isTargetShown, _
				"status": getStatus(isHeadCreated, isHeadDeleted), _ 
				"uiindex": i_ui, "headid": headid, "oheadid": i_oheadid))
	End If
	Return True
End Sub

private Sub getStatus(created As Boolean , deleted As Boolean) As Int
	If created And deleted Then
		Return 3
	End If
	If (created Or deleted) = False Then
		Return 0
	End If
	If created = True And deleted = False Then
		Return 2
	End If
	If created = False And deleted = True Then
		Return 1
	End If
	Return -1
End Sub

'Public Sub FillTheMap() As Boolean	
'	If File.Exists(File.DirAssets, "content.json") = False Then
'		Return False
'	End If
'	If mapOne.IsInitialized And mapOne.Size > 0 Then
'		mapOne.clear
'	End If	
'	Dim jparser As JSONParser
'	Try
'		jparser.Initialize(File.ReadString(File.DirAssets, "content.json"))
'		Dim maptmp As Map = jparser.NextObject
'		For Each key As String In maptmp.Keys
'			'Type conversion
'			Dim intKey As Int = key			
'			mapOne.Put(intKey, maptmp.Get(key))
'		Next
'		If SubExists(m_callback, m_event) Then
'			CallSubDelayed2(m_callback, m_event, CreateMap("action": "filled"))
'		End If
'		Return True
'	Catch
'		Log(LastException)
'		Return False
'	End Try
'End Sub

Public Sub FillTheMap2() As Boolean	
	If File.Exists(File.DirAssets, "content2.json") = False Then
		Return False
	End If
	If mapOne.IsInitialized And mapOne.Size > 0 Then
		mapOne.clear
	End If	
	If mapHeader.IsInitialized  And mapHeader.Size > 0 Then
		mapHeader.Clear
	End If
	If mapLine.IsInitialized And mapLine.Size > 0 Then
		mapLine.Clear
	End If
	Dim jparser As JSONParser
	Try
		jparser.Initialize(File.ReadString(File.DirAssets, "content2.json"))
		Dim maptmp As Map = jparser.NextObject
		For Each key As String In maptmp.Keys
			'Type conversion
			Dim intKey As Int = key		
			Dim innerMap As Map = maptmp.Get(key)
			Dim innerList As List = innerMap.Get("line")
			Dim lst As List : lst.Initialize
			For Each mapEntry As Map In innerList
				mapLine.Put(mapEntry.Get("id"), _ 
					CreateMap("item": mapEntry.Get("item"), "qty": mapEntry.Get("qty")))
				lst.Add(mapEntry.Get("id"))
			Next
			mapHeader.Put(intKey, innerMap.Get("head"))			
			mapShow.Put(intKey, 1)
			mapOne.Put(intKey, lst)
			Dim qty_1 As Int = getHeaderSum(intKey)
			Dim count_1 As Int = getHeaderCount(intKey)
			mapSum.Put(intKey, qty_1)
			mapCount.Put(intKey, count_1)
		Next
		'LogStructure("mapOne", mapOne)
		'LogStructure("mapHeader", mapHeader)
		'LogStructure("mapLine", mapLine)
		If SubExists(m_callback, m_event) Then
			CallSubDelayed2(m_callback, m_event, CreateMap("action": "filled"))
		End If
		Return True
	Catch
		Log(LastException)
		Return False
	End Try	
End Sub

Public Sub AddItem(i_map As Map) As Boolean
	
	If i_map.IsInitialized = False Then
		Return False
	End If
	If i_map.Size <> 2 Then
		Return False
	End If
	If i_map.ContainsKey("head") And i_map.ContainsKey("line") Then
		' is head exist?
		Dim mapEntry As Map = i_map.Get("head")
		Dim foundId As Int = getHeadIdByText(mapEntry.Get("text"))
		If foundId = -1 Then
			'new head
			Dim maxheadkey As Int = getMaxKeyInMap(mapHeader)
			Dim maxlinekey As Int = getMaxKeyInMap(mapLine)
			mapHeader.Put(maxheadkey + 1, i_map.Get("head"))
			Dim innermap As Map = i_map.Get("line")
			Dim qty As Int = innermap.Get("qty")
			mapSum.Put(maxheadkey + 1, qty)
			mapCount.Put(maxheadkey + 1, 1)
			mapShow.Put(maxheadkey + 1, 1)
			mapLine.Put(maxlinekey + 1, i_map.Get("line"))
			Dim lst As List : lst.Initialize
			lst.Add(maxlinekey + 1)
			mapOne.Put(maxheadkey + 1, lst)
			If SubExists(m_callback, m_event) Then
				CallSubDelayed2(m_callback, m_event, _ 
					CreateMap("action": "headadded", "headid": (maxheadkey+1), "lineid": (maxlinekey + 1)))
			End If
		Else
			'existing head
			'mapHeader no need to update
			Dim maxlinekey_1 As Int = getMaxKeyInMap(mapLine)
			mapLine.Put(maxlinekey_1 + 1, i_map.Get("line"))			
			Dim lst_1 As List = mapOne.Get(foundId)
			lst_1.Add(maxlinekey_1 + 1)
			Dim innermap As Map = i_map.Get("line")
			Dim qty_1 As Int = getHeaderSum(foundId)
			Dim count_1 As Int = getHeaderCount(foundId)
			mapSum.Put(foundId, qty_1)
			mapCount.Put(foundId, count_1)			
			If SubExists(m_callback, m_event) Then
				CallSubDelayed2(m_callback, m_event, _ 
					CreateMap("action": "lineadded", "headid": foundId, "lineid": (maxlinekey_1 + 1)))
			End If
		End If		
		Return True
	End If
	Return False	
End Sub

Public Sub EditHead(i_map As Map) As Boolean
	If i_map.IsInitialized = False Then
		Return False
	End If
	If i_map.Size <> 1 Then
		Return False
	End If
	If i_map.ContainsKey("head") Then
		' is head exist?
		Dim mapEntry As Map = i_map.Get("head")
'		Dim foundId As Int = getHeadIdByText(mapEntry.Get("otext"))		
'		If foundId = -1 Then
'			Return False
'		End If
		Dim headid As Int = mapEntry.Get("headid")
		Dim innerMap As Map = mapHeader.Get(headid)
		innerMap.Put("text", mapEntry.Get("text"))
		If SubExists(m_callback, m_event) Then
			CallSubDelayed2(m_callback, m_event, _
				CreateMap("action": "headedited", "uiindex": m_uiindex, "headid": headid))
		End If		
		Return True
	End If
	Return False
End Sub

Public Sub EditLine(i_map As Map) As Boolean
	If i_map.IsInitialized = False Then
		Return False
	End If
	If i_map.Size <> 1 Then
		Return False
	End If
	If i_map.ContainsKey("line") Then
		Dim mapEntry As Map = i_map.Get("line")
		Dim lineid As Int = mapEntry.Get("lineid")
		Dim headid As Int = mapEntry.Get("headid") 
		Dim innerMap As Map = mapLine.Get(lineid)		
		innerMap.Put("item", mapEntry.Get("item"))
		innerMap.Put("qty", mapEntry.Get("qty"))	
		Dim qty As Int = getHeaderSum(headid)
		'Dim count As Int = getHeaderCount(headid)
		mapSum.Put(headid, qty)
		If SubExists(m_callback, m_event) Then
			CallSubDelayed2(m_callback, m_event, _
				CreateMap("action": "lineedited", "uiindex": m_uiindex, "headid": headid, "lineid": lineid))	
		End If
		Return True
	End If
	Return False
End Sub

'Private Sub getHeadIdFromLineId(i_lineid As Int) As Int
'	If mapOne.IsInitialized = False Then
'		Return -1
'	End If
'	For Each key1 As Int In mapOne.Keys
'		Dim lst As List = mapOne.Get(key1)		
'		If lst.IsInitialized Then
'			If lst.IndexOf(i_lineid) > -1 Then
'				Return key1
'			End If
'		End If		
'	Next
'	Return -1
'End Sub

Private Sub getMaxKeyInMap(whichmap As Map) As Int
	Dim maxkey As Int = 0
	For Each key As String In whichmap.Keys
		If IsNumber(key) = False Then
			Continue
		End If
		'Type Conversion
		Dim intkey As Int = key
		If intkey > maxkey Then
			maxkey = intkey
		End If
	Next
	Return maxkey
End Sub

Private Sub getHeaderSum(headid As Int) As Int
	If mapOne.ContainsKey(headid) = False Then
		Return -1
	End If
	Dim lst As List = mapOne.Get(headid)
	Dim sum As Int = 0
	For Each line As Int In lst
		If mapLine.ContainsKey(line) = False Then
			Continue
		End If
		Dim innerMap As Map = mapLine.Get(line)
		Dim qty As Int = innerMap.Get("qty")
		sum = sum + qty
	Next
	Return sum
End Sub

Private Sub getHeaderCount(headid As Int) As Int
	If mapOne.ContainsKey(headid) = False Then
		Return -1
	End If
	Dim lst As List = mapOne.Get(headid)
	Dim count As Int = 0 
	For Each line As Int In lst
		If mapLine.ContainsKey(line) = False Then
			Continue
		End If
		count = count + 1
	Next
	Return count
End Sub

Public Sub DeleteHeader(headid As Int) As Boolean
	If mapOne.ContainsKey(headid) = False Or mapHeader.ContainsKey(headid) = False Then		
		Return False
	End If
	If m_uiindex = -1 Then
		Return False
	End If
	Dim lstTmp As List = mapOne.Get(headid)
	For Each id_1 As Int In lstTmp
		If mapLine.ContainsKey(id_1) Then
			mapLine.Remove(id_1)
		End If		
	Next
	mapSum.Remove(headid)
	mapCount.Remove(headid)
	mapHeader.Remove(headid)
	mapShow.Remove(headid)
	mapOne.Remove(headid)		
	If SubExists(m_callback, m_event) Then
		CallSubDelayed2(m_callback, m_event, _ 
			CreateMap("action": "headdeleted", "uiindex": m_uiindex, "count": lstTmp.Size))
	End If
	Return True
End Sub

Public Sub DeleteItem(headid As Int, lineid As Int) As Boolean
	If mapOne.ContainsKey(headid) = False Or mapHeader.ContainsKey(headid) = False Or mapLine.ContainsKey(lineid) = False Then
		Return False
	End If
	If m_uiindex = -1 Then
		Return False
	End If
	Dim lstTmp As List = mapOne.Get(headid)
	If lstTmp.IsInitialized = False Then
		Return False
	End If
	Dim foundidx As Int = lstTmp.IndexOf(lineid)
	If foundidx = -1 Then
		Return False
	End If
	If lstTmp.Size = 1 Then 'single children
		'if delete a single children, delete its parent too.		
		Dim lstTmp As List = mapOne.Get(headid)
		If mapLine.ContainsKey(lstTmp.Get(0)) Then
			mapLine.Remove(lstTmp.Get(0))
		End If
		mapHeader.Remove(headid)
		mapSum.Remove(headid)
		mapCount.Remove(headid)
		mapShow.Remove(headid)
		mapOne.Remove(headid)
		If SubExists(m_callback, m_event) Then
			CallSubDelayed2(m_callback, m_event, _ 
				CreateMap("action": "headdeleted", "uiindex": m_uiindex-1, "headid": headid, "count": 1))
		End If
	Else
		If mapLine.ContainsKey(lineid) Then
			mapLine.Remove(lineid)
		End If		
		lstTmp.RemoveAt(foundidx)
		mapSum.Put(headid, getHeaderSum(headid))
		mapCount.Put(headid, getHeaderCount(headid))
		If SubExists(m_callback, m_event) Then
			CallSubDelayed2(m_callback, m_event, _ 
				CreateMap("action": "linedeleted", "uiindex": m_uiindex, "headid": headid))
		End If
	End If
	'LogStructure
	Return True
End Sub

Private Sub getHeadIdByText(i_text As String) As Int
	Dim id As Int = -1
	For Each key As Int In mapHeader.Keys
		Dim innermap As Map = mapHeader.Get(key)
		If innermap.ContainsKey("text") = False Then
			Continue
		End If
		If innermap.Get("text") = i_text Then
			id = key
			Exit
		End If
	Next
	Return id
End Sub

Public Sub getTextByHeadId(i_headid As Int) As String
	If mapHeader.ContainsKey(i_headid) = False Then
		Return ""
	End If
	Dim map1 As Map = mapHeader.Get(i_headid)
	Return map1.Get("text")
End Sub

Public Sub getItemByLineId(i_lineid As Int) As String
	If mapLine.ContainsKey(i_lineid) = False Then
		Return ""		
	End If
	Dim map2 As Map = mapLine.Get(i_lineid)
	Return map2.Get("item")
End Sub

Public Sub getQtyByLineId(i_lineid As Int) As Int
	If mapLine.ContainsKey(i_lineid) = False Then
		Return ""		
	End If
	Dim map2 As Map = mapLine.Get(i_lineid)
	Return map2.Get("qty")
End Sub

'Log The structure for debug only
Public Sub LogStructure(i_name As String, i_map As Map)
	Dim jgen As JSONGenerator
	Try
		jgen.Initialize(i_map)
		LogColor(i_name & CRLF & jgen.ToPrettyString(4), Colors.DarkGray)
	Catch
		Log(LastException)
	End Try
End Sub

Public Sub getHeaderList() As List
	Dim lst As List 
	lst.Initialize
	For Each key As Int In mapHeader.Keys
		Dim innermap As Map = mapHeader.Get(key)
		If innermap.ContainsKey("text") = False Then
			Continue
		End If
		Dim text As String = innermap.Get("text")
		lst.Add(text)
	Next
	Return lst
End Sub