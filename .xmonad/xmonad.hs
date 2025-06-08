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
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.EwmhDesktops

import XMonad.Actions.GridSelect (buildDefaultGSConfig)
import XMonad.Actions.CycleWS
import XMonad.Actions.Volume
import XMonad.Actions.FloatSnap
import XMonad.Actions.Promote
import XMonad.Hooks.DynamicLog (dzenColor, dzenEscape, pad, dynamicLogWithPP)
import XMonad.Hooks.StatusBar.PP (def)
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.Dzen

import System.IO
import System.Exit
import Data.Monoid

import qualified XMonad.StackSet as S
import qualified Data.Map as M
 
myTerminal = "sakura"
colorNormalBorder   = "#647702"
colorFocusedBorder  = "#b5ef4a"

myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

myLayout = lessBorders OnlyScreenFloat $ avoidStruts $ smartBorders $ tiled ||| Mirror tiled ||| Full ||| tabs ||| simplestFloat
     where
     tiled = trackFloating $ spacing 3 $ ResizableTall 1 (2/100) (1/2) []
     tabs = simpleTabbed

altMask = mod1Mask
winMask = mod4Mask

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $ 
    [ ((winMask , xK_c), kill)
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
    , ((winMask, xK_g), goToSelected (buildDefaultGSConfig def))
    , ((winMask, xK_b), sendMessage ToggleStruts)
    , ((winMask, xK_comma  ), sendMessage Shrink)
    , ((winMask, xK_period ), sendMessage Expand)
    , ((winMask .|. altMask, xK_comma), sendMessage MirrorShrink)
    , ((winMask .|. altMask, xK_period ), sendMessage MirrorExpand)
    , ((winMask .|. altMask, xK_BackSpace), windows $ S.shift "dump")
    , ((winMask, xK_o), spawn "dmenu_run -b")
    , ((winMask, xK_v), spawn "rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}'")
    , ((0, xK_Print), spawn "scrot -q 95 '%Y-%m-%d_$wx$h.jpg' -e 'mv $f ~/Pictures/'")
    , ((altMask, xK_Print), spawn "maim -s | tee \"/home/maksis/Pictures/$(date +%Y-%m-%d_%H-%M-%S).png\" | xclip -selection clipboard -t image/png -i")
    , ((winMask, xK_bracketleft), sendMessage (IncMasterN 1))
    , ((winMask, xK_bracketright), sendMessage (IncMasterN (-1)))
    , ((winMask, xK_semicolon), sendMessage NextLayout)
    , ((winMask, xK_quotedbl), sendMessage FirstLayout)
    , ((winMask .|. shiftMask, xK_q), io (exitWith ExitSuccess))
    , ((winMask, xK_Return), spawn "rofi -show run")
    , ((winMask, xK_slash), spawn "rofi -show window")
    , ((winMask, xK_r), spawn "rofi -show ssh")
    , ((winMask, xK_q), spawn "killall conky dzen2 trayer && sleep 1" >> (restart "/home/maksis/.xmonad/xmonad-x86_64-linux" True))
    , ((winMask .|. shiftMask, xK_l), spawn "xscreensaver-command -lock")
    , ((0, 0xffc8), lowerVolume 4 >>= alert)
    , ((0, 0xffc9), raiseVolume 4 >>= alert) 
    , ((winMask, xK_Left), lowerVolume 4 >>= alert)
    , ((winMask, xK_Right), raiseVolume 4 >>= alert)
    , ((winMask, xK_t), spawn myTerminal)
    ]
    ++
    [ ((m .|. winMask, k), windows $ f i)
      | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
      , (f, m) <- [(S.greedyView, 0), (S.shift, altMask)]
    ]
    where alert = dzenConfig return . show

myMouseBindings (XConfig {XMonad.modMask = winMask}) = M.fromList $
  [ ((0, button3), \w -> focus w >> mouseMoveWindow w >> windows S.shiftMaster)
  , ((winMask .|. altMask, button1), \w -> focus w >> mouseMoveWindow w >> snapMagicMove (Just 50) (Just 50) w)
  , ((winMask, button1), \w -> focus w >> mouseMoveWindow w >> windows S.shiftMaster)
  , ((winMask, button2), \w -> focus w >> windows S.shiftMaster)
  ]

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

myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ def
  { ppCurrent = dzenColor "#98cc0a" "#101e00" . pad
  , ppVisible = dzenColor "white" "#101e00" . pad
  , ppHidden = dzenColor "white" "#101e00" . pad
  , ppHiddenNoWindows = dzenColor "#7b7b7b" "#101e00" . pad
  , ppUrgent = dzenColor "#ff0000" "#101e00" . pad
  , ppWsSep = " "
  , ppSep = "  |  "
  , ppLayout = dzenColor "#98cc0a" "#101e00" . (\x -> case x of
      "Spacing ResizableTall" -> "^i(" ++ myBitmapsDir ++ "/tall.xbm)"
      "Mirror Spacing ResizableTall" -> "^i(" ++ myBitmapsDir ++ "/mtall.xbm)"
      "Full" -> "^i(" ++ myBitmapsDir ++ "/full.xbm)"
      "Tabbed Simplest" -> "~"
      _ -> x)
  , ppTitle = (" " ++) . dzenColor "white" "#101e00" . dzenEscape
  , ppOutput = hPutStrLn h
  }

-- myManageHook, startup, bars etc. remain unchanged below...
-- (omit re-pasting that section unless you need fixes there too)

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
      handleEventHook = myEventHook >> docksEventHook,
      startupHook = myStartup,
      logHook = myLogHook dzenLeftBar >> fadeInactiveLogHook 0xdddddddd,
      normalBorderColor = colorNormalBorder,
      focusedBorderColor = colorFocusedBorder,
      borderWidth = 3
    }
