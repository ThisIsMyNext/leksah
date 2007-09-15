--
-- | Module for menus and toolbars
--

module Ghf.Menu (
    actions
,   menuDescription
,   makeMenu
,   quit
,   aboutDialog
,   version
) where

import Graphics.UI.Gtk
import Graphics.UI.Gtk.Types
import qualified Data.Map as Map
import Data.Map (Map,(!))
import Control.Monad.Reader
import System.FilePath

import Ghf.Core
import Ghf.SourceEditor
import Ghf.ViewFrame
import {-# SOURCE #-} Ghf.PreferencesEditor(editPrefs)
import Ghf.PackageEditor
import Ghf.Package
import Ghf.Log
import Ghf.SaveLayout

version = "0.1"

actions :: [ActionDescr]
actions =
    [(AD "File" "_File" Nothing Nothing (return ()) [] False)
    ,(AD "FileNew" "_New" Nothing (Just "gtk-new")
        fileNew [] False)
    ,AD "FileOpen" "_Open" Nothing (Just "gtk-open")
        fileOpen [] False
    ,AD "FileSave" "_Save" Nothing (Just "gtk-save")
        (fileSave False) [] False
    ,AD "FileSaveAs" "Save_As" Nothing (Just "gtk-save_as")
        (fileSave True) [] False
    ,AD "FileClose" "_Close" Nothing (Just "gtk-close")
        (do fileClose; return ()) [] False
    ,AD "Quit" "_Quit" Nothing (Just "gtk-quit")
        quit [] False

    ,AD "Edit" "_Edit" Nothing Nothing (return ()) [] False
    ,AD "EditUndo" "_Undo" Nothing (Just "gtk-undo")
        editUndo [] False
    ,AD "EditRedo" "_Redo" Nothing (Just "gtk-redo")
        editRedo [] False
    ,AD "EditCut" "Cu_t" Nothing Nothing{--Just "gtk-cut"--}
        editCut [] {--Just "<control>X"--} False
    ,AD "EditCopy" "_Copy"  Nothing  Nothing{--Just "gtk-copy"--}
        editCopy [] {--Just "<control>C"--} False
    ,AD "EditPaste" "_Paste" Nothing Nothing{--Just "gtk-paste"--}
        editPaste [] {--Just "<control>V"--} False
    ,AD "EditDelete" "_Delete" Nothing (Just "gtk-delete")
        editDelete [] False
    ,AD "EditSelectAll" "Select_All" Nothing (Just "gtk-select-all")
        editSelectAll [] False
    ,AD "EditFind" "_Find" Nothing (Just "gtk-find")
        editFindShow [] False
    ,AD "EditFindNext" "Find _Next" Nothing (Just "gtk-find-next")
        (editFindInc Forward) [] False
    ,AD "EditFindPrevious" "Find _Previous" Nothing (Just "gtk-find-previous")
        (editFindInc Backward) [] False
    ,AD "EditReplace" "_Replace" Nothing (Just "gtk-replace")
        replaceDialog [] False
    ,AD "EditGotoLine" "_Goto Line" Nothing (Just "gtk-jump")
        editGotoLine [] False

    ,AD "EditComment" "_Comment" Nothing Nothing
        editComment [] False
    ,AD "EditUncomment" "_Uncomment" Nothing Nothing
        editUncomment [] False
    ,AD "EditShiftRight" "Shift _Right" Nothing Nothing
        editShiftRight [] False
    ,AD "EditShiftLeft" "Shift _Left" Nothing Nothing
        editShiftLeft [] False

    ,AD "EditCandy" "_To Candy" Nothing Nothing
        editCandy [] True

    ,AD "Package" "Package" Nothing Nothing (return ()) [] False
    ,AD "NewPackage" "_New Package" Nothing Nothing
        packageNew [] False
    ,AD "EditPackage" "_Edit Package" Nothing Nothing
        (packageEdit Nothing) [] False
    ,AD "ConfigPackage" "_Configure Package" Nothing Nothing
        (packageConfig True) [] False
    ,AD "BuildPackage" "_Build Package" Nothing Nothing
        (packageBuild False) [] False
    ,AD "DocPackage" "_Build Documentation" Nothing Nothing
        packageDoc [] False
    ,AD "CleanPackage" "Cl_ean Package" Nothing Nothing
        packageClean [] False
    ,AD "CopyPackage" "_Build Package" Nothing Nothing
        packageCopy [] False
    ,AD "RunPackage" "_Run" Nothing Nothing
        packageRun [] False

    ,AD "InstallPackage" "_Install Package" Nothing Nothing
        packageInstall [] False
    ,AD "RegisterPackage" "_Register Package" Nothing Nothing
        packageRegister [] False
    ,AD "UnregisterPackage" "_Unregister" Nothing Nothing
        packageUnregister [] False
    ,AD "TestPackage" "Test Package" Nothing Nothing
        packageTest [] False
    ,AD "SdistPackage" "Source Dist" Nothing Nothing
        packageSdist [] False
    ,AD "OpenDocPackage" "_Open Doc" Nothing Nothing
        packageOpenDoc [] False



    ,AD "View" "_View" Nothing Nothing (return ()) [] False
    ,AD "ViewMoveLeft" "Move _Left" Nothing Nothing
        (viewMove LeftP) [] False
    ,AD "ViewMoveRight" "Move _Right" Nothing Nothing
        (viewMove RightP) [] False
    ,AD "ViewMoveUp" "Move _Up" Nothing Nothing
        (viewMove TopP) [] False
    ,AD "ViewMoveDown" "Move _Down" Nothing Nothing
        (viewMove BottomP) [] False
    ,AD "ViewSplitHorizontal" "Split H_orizontal" Nothing Nothing
        viewSplitHorizontal [] False
    ,AD "ViewSplitVertical" "Split _Vertical" Nothing Nothing
        viewSplitVertical [] False
    ,AD "ViewCollapse" "_Collapse" Nothing Nothing
        viewCollapse [] False

    ,AD "ViewTabsLeft" "Tabs Left" Nothing Nothing
        (viewTabsPos PosLeft) [] False
    ,AD "ViewTabsRight" "Tabs Right" Nothing Nothing
        (viewTabsPos PosRight) [] False
    ,AD "ViewTabsUp" "Tabs Up" Nothing Nothing
        (viewTabsPos PosTop) [] False
    ,AD "ViewTabsDown" "Tabs Down" Nothing Nothing
        (viewTabsPos PosBottom) [] False
    ,AD "ViewSwitchTabs" "Tabs On/Off" Nothing Nothing
        viewSwitchTabs [] False

    ,AD "Preferences" "_Preferences" Nothing Nothing (return ()) [] False
    ,AD "PrefsEdit" "_Edit Prefs" Nothing Nothing
        editPrefs [] False


    ,AD "Help" "_Help" Nothing Nothing (return ()) [] False
    ,AD "HelpDebug" "Debug" (Just "<Ctrl>d") Nothing helpDebug [] False
    ,AD "HelpAbout" "About" Nothing (Just "gtk-about") aboutDialog [] False]


menuDescription :: String
menuDescription = "\n\
 \<ui>\n\
   \<menubar>\n\
     \<menu name=\"_File\" action=\"File\">\n\
       \<menuitem name=\"_New\" action=\"FileNew\" />\n\
       \<menuitem name=\"_Open\" action=\"FileOpen\" />\n\
       \<separator/>\n\
       \<menuitem name=\"_Save\" action=\"FileSave\" />\n\
       \<menuitem name=\"Save_As\" action=\"FileSaveAs\" />\n\
       \<separator/>\n\
       \<menuitem name=\"_Close\" action=\"FileClose\" />\n\
       \<menuitem name=\"_Quit\" action=\"Quit\" />\n\
     \</menu>\n\
     \<menu name=\"_Edit\" action=\"Edit\">\n\
       \<menuitem name=\"_Undo\" action=\"EditUndo\" />\n\
       \<menuitem name=\"_Redo\" action=\"EditRedo\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Cu_t\" action=\"EditCut\" />\n\
       \<menuitem name=\"_Copy\" action=\"EditCopy\" />\n\
       \<menuitem name=\"_Paste\" action=\"EditPaste\" />\n\
       \<menuitem name=\"_Delete\" action=\"EditDelete\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Select _All\" action=\"EditSelectAll\" />\n\
       \<separator/>\n\
       \<menuitem name=\"_Find\" action=\"EditFind\" />\n\
       \<menuitem name=\"Find_Next\" action=\"EditFindNext\" />\n\
       \<menuitem name=\"Find_Previous\" action=\"EditFindPrevious\" />\n\
       \<menuitem name=\"_Goto Line\" action=\"EditGotoLine\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Replace\" action=\"EditReplace\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Comment\" action=\"EditComment\" />\n\
       \<menuitem name=\"Uncomment\" action=\"EditUncomment\" />\n\
       \<menuitem name=\"Shift Left\" action=\"EditShiftLeft\" />\n\
       \<menuitem name=\"Shift Right\" action=\"EditShiftRight\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Source Candy\" action=\"EditCandy\" />\n\
     \</menu>\n\
    \<menu name=\"_Package\" action=\"Package\">\n\
       \<menuitem name=\"_New Package\" action=\"NewPackage\" />\n\
       \<menuitem name=\"_Edit Package\" action=\"EditPackage\" />\n\
       \<separator/>\n\
       \<menuitem name=\"_Configure Package\" action=\"ConfigPackage\" />\n\
       \<menuitem name=\"_Build Package\" action=\"BuildPackage\" />\n\
       \<menuitem name=\"_Run\" action=\"RunPackage\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Clea_n Package\" action=\"CleanPackage\" />\n\
       \<menuitem name=\"C_opy Package\" action=\"CopyPackage\" />\n\
       \<menuitem name=\"_Install Package\" action=\"InstallPackage\" />\n\
       \<menuitem name=\"Re_gister Package\" action=\"RegisterPackage\" />\n\
       \<menuitem name=\"_Unregister Package\" action=\"UnregisterPackage\" />\n\
       \<menuitem name=\"Test Package\" action=\"TestPackage\" />\n\
       \<menuitem name=\"SDist Package\" action=\"SdistPackage\" />\n\
       \<separator/>\n\
       \<menuitem name=\"_Build Documentation\" action=\"DocPackage\" />\n\
       \<menuitem name=\"Open Documentation\" action=\"OpenDocPackage\" />\n\
     \</menu>\n\
    \<menu name=\"_View\" action=\"View\">\n\
       \<menuitem name=\"Move _Left\" action=\"ViewMoveLeft\" />\n\
       \<menuitem name=\"Move _Right\" action=\"ViewMoveRight\" />\n\
       \<menuitem name=\"Move _Up\" action=\"ViewMoveUp\" />\n\
       \<menuitem name=\"Move _Down\" action=\"ViewMoveDown\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Split H_orizontal\" action=\"ViewSplitHorizontal\" />\n\
       \<menuitem name=\"Split V_ertical\" action=\"ViewSplitVertical\" />\n\
       \<menuitem name=\"_Collapse\" action=\"ViewCollapse\" />\n\
       \<separator/>\n\
       \<menuitem name=\"Tabs _Left\" action=\"ViewTabsLeft\" />\n\
       \<menuitem name=\"Tabs _Right\" action=\"ViewTabsRight\" />\n\
       \<menuitem name=\"Tabs _Up\" action=\"ViewTabsUp\" />\n\
       \<menuitem name=\"Tabs _Down\" action=\"ViewTabsDown\" />\n\
       \<menuitem name=\"Switch Tabs\" action=\"ViewSwitchTabs\" />\n\
     \</menu>\n\
    \<menu name=\"_Preferences\" action=\"Preferences\">\n\
       \<menuitem name=\"Edit Preferences\" action=\"PrefsEdit\" />\n\
     \</menu>\n\
    \<menu name=\"_Help\" action=\"Help\">\n\
       \<menuitem name=\"_Debug\" action=\"HelpDebug\" />\n\
       \<menuitem name=\"_About\" action=\"HelpAbout\" />\n\
     \</menu>\n\
   \</menubar>\n\
    \<toolbar>\n\
     \<placeholder name=\"FileToolItems\">\n\
       \<separator/>\n\
       \<toolitem name=\"New\" action=\"FileNew\"/>\n\
       \<toolitem name=\"Open\" action=\"FileOpen\"/>\n\
       \<toolitem name=\"Save\" action=\"FileSave\"/>\n\
       \<toolitem name=\"Close\" action=\"FileClose\"/>\n\
       \<separator/>\n\
     \</placeholder>\n\
     \<placeholder name=\"FileEditItems\">\n\
       \<separator/>\n\
       \<toolitem name=\"Undo\" action=\"EditUndo\"/>\n\
       \<toolitem name=\"Redo\" action=\"EditRedo\"/>\n\
       \<separator/>\n\
     \</placeholder>\n\
   \</toolbar>\n\
 \</ui>"

makeMenu :: UIManager -> [ActionDescr] -> String -> GhfM (AccelGroup, [Maybe Widget])
makeMenu uiManager actions menuDescription = do
    ghfR <- ask
    lift $ do
        actionGroupGlobal <- actionGroupNew "global"
        mapM_ (actm ghfR actionGroupGlobal) actions
        uiManagerInsertActionGroup uiManager actionGroupGlobal 1
        uiManagerAddUiFromString uiManager menuDescription
        accGroup <- uiManagerGetAccelGroup uiManager
        widgets <- mapM (uiManagerGetWidget uiManager) ["ui/menubar","ui/toolbar"]
        return (accGroup,widgets)
    where
        actm ghfR ag (AD name label tooltip stockId ghfAction accs isToggle) = do
            let (acc,accString) = if null accs
                                    then (Nothing,"=" ++ name)
                                    else (Just (head accs),(head accs) ++ "=" ++ name)
            if isToggle
                then do
                    act <- toggleActionNew name label tooltip stockId
                    onToggleActionToggled act (doAction ghfAction ghfR accString)
                    actionGroupAddActionWithAccel ag act acc
                else do
                    act <- actionNew name label tooltip stockId
                    onActionActivate act (doAction ghfAction ghfR accString)
                    actionGroupAddActionWithAccel ag act acc
        doAction ghfAction ghfR accStr =
            runReaderT (do
                ghfAction
                sb <- getSpecialKeys
                lift $statusbarPop sb 1
                lift $statusbarPush sb 1 $accStr
                return ()) ghfR


quit :: GhfAction
quit = do
    bufs    <- allBuffers
    saveLayout
    if null bufs
        then    lift mainQuit
        else    do  r <- mapM (\ b -> do    makeBufferActive b
                                            fileClose) bufs
                    if foldl (&&) True r
                        then lift mainQuit
                        else return ()

aboutDialog :: GhfAction
aboutDialog = lift $ do
    d <- aboutDialogNew
    aboutDialogSetName d "Genuine Haskell Face"
    aboutDialogSetVersion d version
    aboutDialogSetCopyright d "Copyright 2007 Juergen Nicklisch-Franken aka Jutaro"
    aboutDialogSetComments d $ "An integrated development environement (IDE) for the " ++
                               "programming language haskell and the Glasgow Haskell compiler"
    license <- readFile "gpl.txt"
    aboutDialogSetLicense d $ Just license
    aboutDialogSetWebsite d "www.haskell.org/ghf"
    aboutDialogSetAuthors d ["Juergen Nicklisch-Franken aka Jutaro"]
    dialogRun d
    widgetDestroy d
    return ()


