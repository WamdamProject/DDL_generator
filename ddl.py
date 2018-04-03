#!/usr/bin/env python
# -*- coding: utf-8 -*-#

"""
DDL Generator
"""
import wx, os
# from icons.icons import licence

class pyDDl(wx.App):

    def OnInit(self):
        # self.oDB = model.sq.cSqlite()
        # self.oError = tools.Error()

        # t = threading.Thread(target=self.Start())
        # t.start()
        # t.join()
        self.Start()
        return True

    def Start(self):
        import WX_viewer.DDL_creater_projectfrm_home as fMain
        mn = fMain.DDL_creater_projectfrm_home(None)

        # imageFilePath = os.getcwdu() + "/icons/WaMDaM_Logo.PNG"
        # png = wx.Bitmap('image.png', wx.BITMAP_TYPE_PNG)
        # wx.StaticBitmap(self, -1, png, (10, 5), (png.GetWidth(), png.GetHeight()))
        mn.Show()

    def OnExit(self):
        wx.App.ExitMainLoop(self)

def main():
    application = pyDDl()
    application.MainLoop()

if __name__ == '__main__':
    main()
