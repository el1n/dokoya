// 2>NUL & cl /nologo /utf-8 /O2 /Fedoko%1.exe /TP %0 && cl /nologo /utf-8 /O2 /Fedoko%1.dll /TP /LD %0 & GOTO EOF
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <windows.h>
#include <ole2.h>
#include <OleAuto.h>
#include <uiautomation.h>
#include <vector>
#pragma comment(lib,"user32.lib")
#pragma comment(lib,"ole32.lib")
#pragma comment(lib,"OleAut32.lib")

IUIAutomation *uia;

struct{
	char *ClassName;
	char *WindowText;
	char *ControlName;
}c[] = {
	// IE
	{"IEFrame","","Address"},
	{"IEFrame","","アドレス"},
	// Chrome
	{"Chrome_WidgetWin_1","","Address and search bar"},
	{"Chrome_WidgetWin_1","","アドレス検索バー"},
	// Firefox
	{"MozillaWindowClass","","Search or enter address"},
	{"MozillaWindowClass","","URL または検索語句を入力します"},
	// Opera
	{"Chrome_WidgetWin_1","","Address field"},
	{"Chrome_WidgetWin_1","","アドレス欄"},
	// Vivaldi
	// --force-renderer-accessibility
	{"Chrome_WidgetWin_1","","Search or enter an address"},
	{"Chrome_WidgetWin_1","","検索またはアドレスを入力"},
	//
//	{"","",""},
};

BOOL CALLBACK EnumWindowsProc(HWND hwnd,LPARAM lParam)
{
	((std::vector<HWND>*)lParam)->push_back(hwnd);
	return(TRUE);
}

extern "C" __declspec(dllexport) BOOL __cdecl doko(char *r,int z)
{
	OSVERSIONINFO osv;
	IUIAutomation *uia;
	IUIAutomationElement *e;
	IUIAutomationElement *e2;
	IUIAutomationCondition *con;
	double d;
	std::vector<HWND> h;
	char s[2][256];
	char *p;
	VARIANT v;

	osv.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	if(!GetVersionEx(&osv)){
		return(1);
	}
	d = osv.dwMajorVersion + (double)osv.dwMinorVersion / 10;

	if(CoInitialize(NULL)){
		return(1);
	}
	if(CoCreateInstance(d > 6.1 ? CLSID_CUIAutomation8 : CLSID_CUIAutomation,NULL,CLSCTX_INPROC_SERVER,IID_PPV_ARGS(&uia))){
		return(1);
	}

	EnumWindows(EnumWindowsProc,(LPARAM)&h);

	for(int i = 0;i < h.size();++i){
		if(IsWindowVisible(h[i])){
			GetClassName(h[i],s[0],256);
			GetWindowText(h[i],s[1],256);
			printf("[%3d] %s (%08x:%s)\n",i,s[1],h[i],s[0]);

			for(int j = 0;j < sizeof(c) / sizeof(c[0]);++j){
				if(strstr(s[0],c[j].ClassName) && strstr(s[1],c[j].WindowText)){
					if(uia->ElementFromHandle(h[i],&e) == S_OK){
						ZeroMemory(s,sizeof(s));
						MultiByteToWideChar(CP_ACP,0,c[j].ControlName,strlen(c[j].ControlName),(LPWSTR)s,512);
						v.vt = VT_BSTR;
						v.bstrVal = SysAllocString((OLECHAR*)s);
						uia->CreatePropertyCondition(UIA_NamePropertyId,v,&con);
						SysFreeString(v.bstrVal);

						if(e->FindFirst(TreeScope_Subtree,con,&e2) == S_OK && e2 != NULL){
							e2->GetCurrentPropertyValue(UIA_ValueValuePropertyId,&v);
							e2->Release();
							e->Release();
							uia->Release();
							CoUninitialize();

							ZeroMemory(s,sizeof(s));
							WideCharToMultiByte(CP_ACP,0,v.bstrVal,-1,(LPSTR)s,512,NULL,NULL);
							if(p = strstr((char*)s,"://")){
								strcpy((char*)s,p + 3);
							}
							if(p = strchr((char*)s,'/')){
								*p = NULL;
							}
							if(p = strchr((char*)s,'@')){
								strcpy((char*)s,p + 1);
							}
							if(p = strchr((char*)s,':')){
								*p = NULL;
							}

							if(r != NULL){
								strncpy(r,(char*)s,z);
							}else{
								printf("%s\n",s);
							}
							return(0);
						}
						e->Release();
					}
				}
			}
		}
	}
	uia->Release();
	CoUninitialize();

	return(0);
}

int main(void)
{
	return(doko(NULL,0));
}
/*
:EOF
@REM */
