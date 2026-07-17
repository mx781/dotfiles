-- Import statements
import XMonad

import XMonad.Config.Desktop

import XMonad.Layout.NoBorders 
import XMonad.Layout.PerWorkspace (onWorkspace, onWorkspaces)
import XMonad.Layout.Reflect (reflectHoriz)
import XMonad.Layout.IM
import XMonad.Layout.TrackFloating
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Tabbed
import XMonad.Layout.Spacing
import XMonad.Layout.ResizableTile
import XMonad.Layout.LayoutHints
import XMonad.Layout.LayoutModifier
import XMonad.Layout.Grid

import XMonad.Operations

import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.EwmhDesktops

import XMonad.Actions.GridSelect
import XMonad.Actions.CycleWS
import XMonad.Actions.Volume
import XMonad.Actions.FloatSnap
import XMonad.Actions.Promote
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.Dzen
import Theme

import System.IO
import System.Exit
import Data.Monoid

import qualified XMonad.StackSet as S
import qualified Data.Map as M
 
myTerminal = "alacritty"
colorNormalBorder   = themeBorderNormal
colorFocusedBorder  = themeBorderFocused

-- Define the names of all workspaces
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]


myLayout = lessBorders OnlyScreenFloat $ avoidStruts $ smartBorders $ tiled ||| Mirror tiled ||| Full ||| tabs ||| simplestFloat
     where
     tiled = trackFloating $ spacingRaw False (Border 0 0 0 0) False (Border 3 3 3 3) True $ ResizableTall 1 (2/100) (1/2) []
     tabs = simpleTabbed

altMask = mod1Mask
winMask = mod4Mask

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $ 
    [ 
        -- Close window
        ((winMask , xK_c), kill)

        -- Workspace / window management (win)
  -- isFloating ? bring to master
  -- place allwindows shift p
        , ((winMask, xK_j), windows S.focusDown)
        , ((winMask, xK_k), windows S.focusUp)
        , ((winMask .|. altMask, xK_j), windows S.swapDown)
        , ((winMask .|. altMask, xK_k), windows S.swapUp)
  , ((winMask, xK_m), windows S.focusMaster)
  , ((winMask .|. altMask, xK_m), windows S.swapMaster)
        , ((winMask, xK_p), withFocused $ windows . S.sink)
        , ((altMask, xK_Tab), windows S.focusDown)
        , ((altMask .|. shiftMask, xK_Tab), windows S.focusUp)
        , ((winMask, xK_Tab), toggleWS)
  , ((winMask, xK_n), moveTo Next EmptyWS)
        , ((winMask, xK_h), prevWS)
        , ((winMask, xK_l), nextWS)
  , ((winMask, xK_BackSpace), nextScreen)
  , ((winMask .|. altMask, xK_BackSpace), shiftNextScreen)
        , ((winMask .|. altMask, xK_h), shiftToPrev >> prevWS)
        , ((winMask .|. altMask, xK_l), shiftToNext >> nextWS)
        , ((winMask, xK_g), goToSelected def)
  , ((winMask, xK_b), sendMessage ToggleStruts)
  , ((winMask, xK_comma  ), sendMessage Shrink)
  , ((winMask, xK_period ), sendMessage Expand)
  , ((winMask .|. altMask, xK_comma), sendMessage MirrorShrink)
  , ((winMask .|. altMask, xK_period ), sendMessage MirrorExpand)
  , ((winMask .|. altMask, xK_BackSpace), windows $ S.shift "dump")
  , ((winMask, xK_o), spawn $ "dmenu_run -i -sb '" ++ themeAccent ++ "' -fn 'Fira Code'")
  , ((winMask, xK_Return), spawn $ "dmenu_run -i -sb '" ++ themeAccent ++ "' -fn 'Fira Code'")
  , ((winMask, xK_v), spawn $ "clipmenu -i -sb '" ++ themeAccent ++ "' -fn 'Fira Code'")
  , ((0, xK_Print), spawn "scrot -q 95 '%Y-%m-%d_$wx$h.jpg' -e 'mv $f ~/Pictures/'")
  , ((altMask, xK_Print), spawn "maim -s | tee \"/home/maksis/Pictures/$(date +%Y-%m-%d_%H-%M-%S).png\" | xclip -selection clipboard -t image/png -i")
  -- , ((winMask .|. altMask, xK_p), spawn "scrot -s -q 95 ~/Pictures/%Y-%m-%d_%H-%M-%S.jpg -e 'xclip -selection clipboard -t image/jpg -i $f'")
  , ((winMask, xK_bracketleft), sendMessage (IncMasterN 1))
  , ((winMask, xK_bracketright), sendMessage (IncMasterN (-1)))
        , ((winMask, xK_semicolon), sendMessage NextLayout)
        , ((winMask, xK_quotedbl), sendMessage FirstLayout)
  , ((winMask .|. shiftMask, xK_q), io (exitWith ExitSuccess))
  -- TODO
  -- , ((winMask, xK_Return), spawn "rofi -run-list-command '. ~/scripts/get_rofi_aliases.sh' -run-command '/bin/bash -i -c \'{cmd}\''  -show run -rnow")
  -- , ((winMask, xK_Return), spawn "rofi -show run")
  , ((winMask, xK_slash), spawn "wmctrl -lx | awk '{print $1 \" \" $3 \" \" substr($0, index($0,$5))}' | dmenu -l 10 -i | awk '{print $1}' |   xargs -r wmctrl -ia")
  -- , ((winMask, xK_r), spawn "rofi -show ssh")
  -- , ((winMask, xK_f), spawn "rofi -show fb -modi fb:~/linux/rofi-file-browser.sh")
  , ((winMask, xK_q), spawn "killall conky dzen2 trayer && sleep 1" >> (restart "/home/maksis/.xmonad/xmonad-x86_64-linux" True))
  , ((winMask .|. shiftMask, xK_l), spawn "xsecurelock")


  , ((0, 0xffc8), lowerVolume 4 >>= alert)
  , ((0, 0xffc9), raiseVolume 4 >>= alert) 
  , ((winMask, xK_Left), lowerVolume 4 >>= alert)
  , ((winMask, xK_Right), raiseVolume 4 >>= alert)  

  -- Programs (alt)
  , ((winMask, xK_t), spawn myTerminal)
  -- , ((winMask, xK_s), spawn "thunar /space/")
  -- , ((winMask, xK_e), spawn "thunar")
  -- , ((winMask, xK_d), spawn "thunar Desktop")
    ]
    ++
    [ ((m .|. winMask, k), windows $ f i)
  | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
  , (f, m) <- [(S.greedyView, 0), (S.shift, altMask)]
    ]
    where
  alert = dzenConfig return . show

myMouseBindings (XConfig {XMonad.modMask = winMask}) = M.fromList $
  [
  ((0, button3), (\w -> focus w >> mouseMoveWindow w >> windows S.shiftMaster))
  ,((winMask .|. altMask, button1), (\w -> focus w >> mouseMoveWindow w >> snapMagicMove (Just 50) (Just 50) w))
  ,((winMask, button1), (\w -> focus w >> mouseMoveWindow w >> windows S.shiftMaster))
  , ((winMask, button2), (\w -> focus w >> windows S.shiftMaster))
  ]

-- Bring clicked window to front
floatClickFocusHandler :: Event -> X All
floatClickFocusHandler ButtonEvent { ev_window = w } = do
  withWindowSet $ \s -> do
    if isFloat w s
       then (focus w >> promote)
       else return ()
    return (All True)
    where isFloat w ss = M.member w $ S.floating ss
floatClickFocusHandler _ = return (All True)

myEventHook = floatClickFocusHandler

--Bar
myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ def
    {
        ppCurrent           =   dzenColor themeAccent themeBackground . pad
      , ppVisible           =   dzenColor themeForeground themeBackground . pad
      , ppHidden            =   dzenColor themeForeground themeBackground . pad
      , ppHiddenNoWindows   =   dzenColor themeMuted themeBackground . pad
      , ppUrgent            =   dzenColor themeUrgent themeBackground . pad
      , ppWsSep             =   " "
      , ppSep               =   "  |  "
      , ppLayout            =   dzenColor themeAccent themeBackground .
                                (\x -> case (x) of
                                    "Spacing ResizableTall"             ->      "^i(" ++ myBitmapsDir ++ "/tall.xbm)"
                                    "Mirror Spacing ResizableTall"      ->      "^i(" ++ myBitmapsDir ++ "/mtall.xbm)"
                                    "Full"                      ->      "^i(" ++ myBitmapsDir ++ "/full.xbm)"
                                    "Tabbed Simplest"              ->      "~"
                                    _                           ->      x
                                )
      , ppTitle             =   (" " ++) . dzenColor themeForeground themeBackground . dzenEscape
      , ppOutput            =   hPutStrLn h
    }

myManageHook :: ManageHook
myManageHook = (composeAll . concat $
    [ [resource     =? r --> doIgnore            |   r   <- myIgnores] -- ignore desktop
    , [className    =? c --> doShift  "1"      |   c   <- myWebs   ] -- move webs to net
    , [className    =? c --> doShift  "2"      |   c   <- myDev    ] -- move webs to main
    , [className    =? c --> doShift  "6"     |   c   <- myChat   ] -- move chat to chat
    , [className    =? c --> doShift  "5"    |   c   <- myMedia  ] -- move dev to main
    , [className    =? c --> doShift  "7"     |   c   <- myDump   ] -- move img to div
    , [className    =? c --> doCenterFloat       |   c   <- myFloats ] -- float my floats
    , [name         =? n --> doCenterFloat       |   n   <- myNames  ] -- float my names
    , [isFullscreen                 --> doFullFloat                  ]
    , [manageDocks]
    ])
  where

  role      = stringProperty "WM_WINDOW_ROLE"
  name      = stringProperty "WM_NAME"

  -- classnames
  myFloats  = ["Smplayer","MPlayer","VirtualBox","Xmessage","XFontSel","Downloads","Nm-connection-editor"]
  myWebs    = ["Opera","Iceweasel","Firefox","Google-chrome","Chromium", "Chromium-browser"]
  myMovie   = ["Boxee","Trine","vlc"]
  myMusic   = ["Rhythmbox","Spotify"]
  myGimp    = ["Gimp"]
  myMedia   = myMusic ++ myMovie ++ myGimp
  myChat    = ["Skype","Pidgin","Telegram"]
  myDev   = ["Gvim"]
  myDump    = []

  -- resources
  myIgnores = ["desktop","desktop_window","notify-osd","stalonetray"]

  -- names
  myNames   = ["bashrun","Google Chrome Options","Chromium Options"]
 

-- single screen
-- myXmonadBar = "dzen2 -dock -x '0' -y '0' -h '18' -w '1520' -ta 'l' -fn 'Carlito:size=11' -fg '#FFFFFF' -bg '#101E00'"
-- myStatusBar = "conky -b -c /home/maksis/.xmonad/.conky_dzen | dzen2 -dock -x '1520' -w '400' -h '18' -ta 'r' -fn 'Carlito:size=11' -bg '#101E00' -fg '#FFFFFF' -y '0'"
-- myTrayer = "trayer --edge top --align right --SetDockType true --expand true --transparent true --tint 0x101E00 --alpha 0 --height 18 --widthtype pixel --width 100 --distancefrom right --distance 400"

-- dual-ultawide
-- myXmonadBar = "dzen2 -dock -x '1920' -y '0' -h '18' -w '3040' -ta 'l' -fn 'Carlito:size=11' -fg '#FFFFFF' -bg '#E35502"
-- myStatusBar = "conky -b -c /home/maksis/.xmonad/.conky_dzen | dzen2 -dock -x '4960' -w '400' -h '18' -ta 'r' -fn 'Carlito:size=11' -bg '#101E00' -fg '#FFFFFF' -y '0'"
-- myTrayer = "trayer --edge top --align right --SetDockType true --expand true --transparent true --tint 0x101E00 --alpha 0 --height 18 --widthtype pixel --width 100 --distancefrom right --distance 400 --monitor 1"

-- dual-ultawide (gravity)
-- myXmonadBar = "dzen2 -dock -x '1920' -y '0' -h '18' -w '3190' -ta 'l' -fn 'Carlito:size=11' -fg '#FFFFFF' -bg '#101E00'"
-- myStatusBar = "conky -b -c /home/maksis/.xmonad/.conky_dzen | dzen2 -dock -x '5210' -w '550' -h '18' -ta 'r' -fn 'Carlito:size=11' -bg '#101E00' -fg '#FFFFFF' -y '0'"
-- myTrayer = "trayer --edge top --align right --SetDockType true --expand true --transparent true --tint 0x101E00 --alpha 0 --height 18 --widthtype pixel --width 100 --distancefrom right --distance 550 --monitor 1"
myDzenGeometry = "/home/maksis/scripts/dzen-geometry"
myXmonadBar = "dzen2 -dock $(" ++ myDzenGeometry ++ " workspace) -ta 'l' -fn 'Carlito:size=11' -fg '" ++ themeForeground ++ "' -bg '" ++ themeBackground ++ "'"
myStatusBar = "conky -b -c /home/maksis/.xmonad/.conky_dzen | dzen2 -dock $(" ++ myDzenGeometry ++ " status) -ta 'r' -fn 'Carlito:size=11' -bg '" ++ themeBackground ++ "' -fg '" ++ themeForeground ++ "'"
myTrayer = "trayer --edge top --align right --SetDockType true --expand true --transparent true --tint 0x101E00 --alpha 0 --height 18 --widthtype pixel --width 100 --distancefrom right --distance 400 --monitor 1"

myStartup = do
  spawn myTrayer
  return()

myBitmapsDir = "/home/maksis/.xmonad/dzen2"

-- Run XMonad with the defaults
main = do
    spawn "feh --bg-fill ~/Pictures/bg-mandra.jpg"
    dzenLeftBar <- spawnPipe myXmonadBar
    dzenRightBar <- spawnPipe myStatusBar
    xmonad $ ewmh desktopConfig {
      terminal = myTerminal,
  workspaces = myWorkspaces,
  keys = myKeys,
  -- mouseBindings = myMouseBindings,
  modMask = winMask,
        manageHook = myManageHook,
  layoutHook = myLayout,
  handleEventHook = do
      myEventHook
      docksEventHook,
  startupHook = myStartup,
  logHook = myLogHook dzenLeftBar >> fadeInactiveLogHook 0xdddddddd,
        normalBorderColor = colorNormalBorder,
        focusedBorderColor = colorFocusedBorder,
        borderWidth = 3
    }
