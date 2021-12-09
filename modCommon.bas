B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=11
@EndOfDesignText@
'Code module
'Subs in this code module will be accessible from all modules.
Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.

End Sub

Public Sub popupMenu2(iList As List) As String
	Dim im As InputMenu
	Dim oResult As Int
	If iList.IsInitialized = True Then
		oResult = im.Show(iList, "Please Select")
		If oResult = -3 Then
			Return ""
		Else
			Return iList.Get(oResult)
		End If
	Else
		Return ""
	End If
End Sub

'https://apps.timwhitlock.info/emoji/tables/unicode
'This UTS function is emoji converter
Public Sub UTS (codepoint As Int) As String
	Dim bc As ByteConverter
	Dim b() As Byte = bc.IntsToBytes(Array As Int(codepoint))
	Return BytesToString(b, 0, 4, "UTF32")
End Sub