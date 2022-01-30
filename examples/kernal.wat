;;Peti asm

;; kernal

(syscall:
  (@vars $call $arg1 $arg2 $arg3 $arg4 $arg5)

  ;; System
  (@if (eq ($call) (0x00)) ( (return (@call reboot ) (0)) ))
  (@if (eq ($call) (0x02)) ( (return (@call printchar ($arg1)) (0)) ))
  (@if (eq ($call) (0x03)) ( (return (@call printstr ($arg1)) (0)) ))
  (@if (eq ($call) (0x04)) ( (return (@call memcopy ($arg1) ($arg2) ($arg3)) (0)) ))
  (@if (eq ($call) (0x05)) ( (return (@call fill ($arg1) ($arg2) ($arg3)) (0)) ))
  (@if (eq ($call) (0x08)) ( (return (@call strtoint ($arg1) ($arg2)) (1)) ))
  (@if (eq ($call) (0x09)) ( (return (@call inttostr ($arg1) ($arg2) ($arg3)) (0)) ))

  ;; Graphics
  (@if (eq ($call) (0x10)) ( (return (@call pset ($arg1) ($arg2) ($arg3)) (0)) ))

  (@if (eq ($call) (0x19)) ( (return (@call scrndepth ) (1)) ))
  (@if (eq ($call) (0x1a)) ( (return (@call scrnwidth ) (1)) ))
  (@if (eq ($call) (0x1b)) ( (return (@call scrnheight ) (1)) ))

  ;; Math
  (@if (eq ($call) (0x20)) ( (return (@call pow ($arg1) ($arg2) ) (1)) ))
)

(reboot:
  (reset)
  (@vars $adr $val)
  (sleep (0x100))
  (set $adr (0xb400))
  (set $val (0x00010203))
  (@while (lt ($adr) (0x10000)) (
    (store ($adr) ($val))
    (set $val (add ($val) (0x04040404)))
    (set $adr (add ($adr) (4)))
  ))
  (@call fill (0) (0xb400) (0x10000-0xb400))

  (@call intro)
  (@if (eq (load8u (0x10000)) (0x10) ) (
    (sys (0) (0x10000) (1))
  ))
  (@call typist)
  (@jump reboot)
)

(intro:
  (@vars
    $sec $ins)
  (store (0xaffc) (0)) ;; text fg color
  (store8 (0xafff) (-1)) ;; text fg color
  (store8 (0xb4f8) (1)) ;; display mode
  (@call printstr (@call memstart))
  (store8 (0xb4f8) (0)) ;; display mode
  (set $sec (load8u (0xb4ee)))
  (@while (eq ($sec) (load8u (0xb4ee)) ) (noop))
  (set $sec (load8u (0xb4ee)))
  (@while (eq ($sec) (load8u (0xb4ee)) ) (
    (set $ins (add ($ins) (15) ))
  ))
  (@call inttostr ($ins) (10) (add (@call memstart) (0x90) ) )
  (@call printstr (add (@call memstart) (0x90) ))
  (@call printstr (add (@call memstart) (0x190) )) ;; ips
  (@call inttostr (sub (memsize) (0x10000)) (10) (add (@call memstart) (0x90) ) )
  (@call printstr (add (@call memstart) (0x90) ))
  (@call printstr (add (@call memstart) (0x70) )) ;; bytes free
  (@call printchar (0x0a))
  (sleep (0x100))
  (@return)
)

(typist:
  (@while (load (0xb4f4)) (
    (store (0xb4f4) (0))
    (vsync)
  ))
  (@call printstr (add (@call memstart) (0x40) ))
  (sys (0x02) (0x81) (0x400) (2))
  (sys (0x02) (0x08) (0x400) (2))
  (@while (true) (
    (@while (eqz (load (0xb4f4))) (
      (vsync)
    ))
    (@if (lt (load8u (0xb4f5)) (0x20)) (
      (sys (0x02) (0x20) (0x400) (2))
      (sys (0x02) (0x08) (0x400) (2))
    ))
    (@call printchar (load8u (0xb4f5)) )
    (sys (0x02) (add (0x82) (load8u (0xb4f7)) ) (0x400) (2))
    (sys (0x02) (0x08) (0x400) (2))
    (store (0xb4f4) (0))
  ))
  (@return)
)

(pset:
  (@vars $x $y $c
    $adr $bit
  )
  (@if (lt ($x) (0)) ( (@return) ))
  (@if (lt ($y) (0)) ( (@return) ))

  (jump (mult (and (7) (load8u (0xb4f8))) (0xc6) ))
  ;; mode 0
  (@if (gt ($x) (511)) ( (@return) )) ;; width-1
  (@if (gt ($y) (287)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (512) ($y))) ) ;; width
  (set $bit (mult (1) (rem ($adr) (8) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (8) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-1)) ) ;; 8 - bits/pixel
    (and (-2) ) ;; -colors
    (xor (and ($c) (1)) ) ;; colors-1
    (rot (sub (8-1) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 1
  (@if (gt ($x) (511)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (512) ($y))) ) ;; width
  (set $bit (mult (2) (rem ($adr) (4) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (4) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-2)) ) ;; 8 - bits/pixel
    (and (-4) ) ;; -colors
    (xor (and ($c) (3)) ) ;; colors-1
    (rot (sub (8-2) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 2
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (4) (rem ($adr) (2) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (2) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-4)) ) ;; 8 - bits/pixel
    (and (-16) ) ;; -colors
    (xor (and ($c) (15)) ) ;; colors-1
    (rot (sub (8-4) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 3
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (71)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (8) (rem ($adr) (1) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (1) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-8)) ) ;; 8 - bits/pixel
    (and (-256) ) ;; -colors
    (xor (and ($c) (255)) ) ;; colors-1
    (rot (sub (8-8) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)

  ;; mode 4
  (@if (gt ($x) (511)) ( (@return) )) ;; width-1
  (@if (gt ($y) (287)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (512) ($y))) ) ;; width
  (set $bit (mult (1) (rem ($adr) (8) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (8) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-1)) ) ;; 8 - bits/pixel
    (and (-2) ) ;; -colors
    (xor (and ($c) (1)) ) ;; colors-1
    (rot (sub (8-1) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 5
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (287)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (2) (rem ($adr) (4) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (4) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-2)) ) ;; 8 - bits/pixel
    (and (-4) ) ;; -colors
    (xor (and ($c) (3)) ) ;; colors-1
    (rot (sub (8-2) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 6
  (@if (gt ($x) (255)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (256) ($y))) ) ;; width
  (set $bit (mult (4) (rem ($adr) (2) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (2) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-4)) ) ;; 8 - bits/pixel
    (and (-16) ) ;; -colors
    (xor (and ($c) (15)) ) ;; colors-1
    (rot (sub (8-4) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
  ;; mode 7
  (@if (gt ($x) (127)) ( (@return) )) ;; width-1
  (@if (gt ($y) (143)) ( (@return) )) ;; height-1
  (set $adr (add ($x) (mult (128) ($y))) ) ;; width
  (set $bit (mult (8) (rem ($adr) (1) ) )) ;; bits/pixel, pixels/byte
  (set $adr (add (0xb800) (div ($adr) (1) ) ) ) ;; pixels/byte
  (store8 ($adr)
    (load8u ($adr))
    (rot (sub ($bit) (8-8)) ) ;; 8 - bits/pixel
    (and (-256) ) ;; -colors
    (xor (and ($c) (255)) ) ;; colors-1
    (rot (sub (8-8) ($bit)) ) ;; 8 - bits/pixel
  )
  (@return)
)

(printchar:
  (@vars $char
    $x1 $y1 $x2 $y2 $x $y $adr $bits)
  (@if (eq ($char) (0x08)) ( ;; backspace
    (store8 (0xaffc) (sub (load8s (0xaffc)) (1) ) )
    (@if (lt (load8s (0xaffc)) (0)) (
      (store8 (0xaffc) (div (@call scrnwidth) (8)))
      (store8 (0xaffd) (sub (load8s (0xaffd)) (1) ) )
      (@if (lt (load8s (0xaffd)) (0)) (
        (store16 (0xaffc) (0) )
      ))
    ))
    (@return)
  ))
  (@if (eq ($char) (0x09)) ( ;; tab
    (store8 (0xaffc) (add (load8u (0xaffc)) (1) ) )
    (@while (rem (load8u (0xaffc)) (8)) (
      (store8 (0xaffc) (add (load8u (0xaffc)) (1) ) )
    ))
    (@return)
  ))
  (@if (eq ($char) (0x0a)) ( ;; newline
    (store8 (0xaffc) (0) )
    (store8 (0xaffd) (add (load8u (0xaffd)) (1) ) )
    (@return)
  ))
  (@if (eq ($char) (0x0d)) ( ;; carriage return
    (store8 (0xaffc) (0) )
    (@return)
  ))
  (@if (lt ($char) (0x20)) (@return))
  (set $x1 (mult (load8u (0xaffc)) (8) ))
  (@if (gt ($x1) (@call scrnwidth)) (
    (store8 (0xaffc) (0) )
    (store8 (0xaffd) (add (load8u (0xaffd)) (1) ) )
    (set $x1 (0))
  ))
  (set $x2 (add ($x1) (8)))
  (set $y1 (mult (load8u (0xaffd)) (8) ))
  (@while (gt ($y1) (@call scrnheight)) (
    (store8 (0xaffd) (sub (load8u (0xaffd)) (1) ) )
    (set $y1 (sub ($y1) (8)))
    (set $adr (add ($adr) (8)))
  ))
  (@call scroll ($adr))
  (set $y2 (add ($y1) (8)))
  (set $adr (add (0xb000) (mult (and ($char) (127)) (8))))
  (set $y ($y1))
  (@while (lt ($y) ($y2)) (
    (set $bits (rot (load8u ($adr)) (-8) ))
    (set $x ($x1))
    (@while (lt ($x) ($x2)) (
      (set $bits (rot ($bits) (1) ))
      (@call pset ($x) ($y) (load8u (add (0xaffe) (and ($bits) (1)) )))
      (set $x (add ($x) (1)))
    ))
    (set $adr (add ($adr) (1)))
    (set $y (add ($y) (1)))
  ))
  (store8 (0xaffc) (add (load8u (0xaffc)) (1) ) )
  (@return)
)

(printstr:
  (@vars $str)
  (@while (load8u ($str)) (
    (@call printchar (load8u ($str)))
    (set $str (add ($str) (1)))
  ))
  (@return)
)

(memcopy:
  (@vars $src $dest $len)
  (@if (gt ($src) ($dest)) (
    (@while (gt ($len) (3)) (
      (store ($dest) (load ($src)))
      (set $src (add ($src) (4)))
      (set $dest (add ($dest) (4)))
      (set $len (sub ($len) (4)))
    ))
    (@while ($len) (
      (store8 ($dest) (load ($src)))
      (set $src (add ($src) (1)))
      (set $dest (add ($dest) (1)))
      (set $len (sub ($len) (1)))
    ))
  ))
  (@if (lt ($src) ($dest)) (
    (set $src (add ($src) ($len)))
    (set $dest (add ($dest) ($len)))
    (@while (gt ($len) (3)) (
      (set $src (sub ($src) (4)))
      (set $dest (sub ($dest) (4)))
      (store ($dest) (load ($src)))
      (set $len (sub ($len) (4)))
    ))
    (@while ($len) (
      (set $src (sub ($src) (1)))
      (set $dest (sub ($dest) (1)))
      (store8 ($dest) (load ($src)))
      (set $len (sub ($len) (1)))
    ))
  ))
  (@return)
)

(fill:
  (@vars $val $dest $len)
  (@while (gt ($len) (3)) (
    (store ($dest) ($val))
    (set $dest (add ($dest) (4)))
    (set $len (sub ($len) (4)))
  ))
  (@while ($len) (
    (store8 ($dest) ($val))
    (set $val (rot ($val) (8)))
    (set $dest (add ($dest) (1)))
    (set $len (sub ($len) (1)))
  ))
  (@return)
)

(strtoint:
  (@vars $str $base
    $int $fact $i $digs)
  (set $digs (add (@call memstart) (0x50)))
  (set $fact (1))
  (@if (eq (load8u ($str)) (0x2d) ) ( ;; minus
    (set $fact (-1))
    (set $str (add ($str) (1)))
  ))
  (@while (load8u ($str)) (
    (@if (eq ($base) (10) ) (
      (@if (eq (load8u ($str)) (0x62) ) ( ;; b
        (set $base (2))
      ))
      (@if (eq (load8u ($str)) (0x6f) ) ( ;; o
        (set $base (8))
      ))
      (@if (eq (load8u ($str)) (0x78) ) ( ;; x
        (set $base (16))
      ))
    ))
    (set $i (0))
    (@while (lt ($i) ($base) ) (
      (@if (or 
        (eq (load8u ($str)) (load8u (add ($digs) ($i) )) )
        (eq (add (load8u ($str)) (0x20) ) (load8u (add ($digs) ($i) )) )
      ) (
        (set $int (mult ($int) ($base) ))
        (set $int (add ($int) ($i) ))
        (set $i ($base))
      ))
      (set $i (add ($i) (1) ))
    ))
    (@if (eq ($i) ($base)) (
      (@return (mult ($int) ($fact)))
    ))
    (set $str (add ($str) (1)))
  ))
  (@return (mult ($int) ($fact)))
)

(inttostr:
  (@vars $int $base $dest
    $start $len $digs)
  (set $digs (add (@call memstart) (0x50)))
  (@if (lt ($int) (0) ) ( ;; minus
    (store8 ($dest) (0x2d) )
    (set $dest (add ($dest) (1) ))
    (set $int (mult ($int) (-1) ))
  ))
  (set $start ($dest))
  (@while ($int) (
    (store8 ($dest) (load8u (add ($digs) (rem ($int) ($base) ) ) ) )
    (set $dest (add ($dest) (1) ))
    (set $int (div ($int) ($base) ))
  ))
  (@if (eq ($start) ($dest) ) (
    (store8 ($dest) (0x30) )
    (set $dest (add ($dest) (1) ))
  ))
  (store8 ($dest) (0) )
  (set $len (div (sub ($dest) ($start) ) (2) ) )
  (@while ($len) (
    (set $dest (sub ($dest) (1) ))
    (set $int (load8u ($dest)))
    (store8 ($dest) (load8u ($start) ) )
    (store8 ($start) ($int) )
    (set $start (add ($start) (1) ))
    (set $len (sub ($len) (1) ))
  ))
  (@return)
)

(scroll:
  (@vars $px
    $adr $offset $end)
  (@if (eqz ($px)) (@return))
  (set $adr (0xb800))
  (set $offset (mult ($px) (@call scrnbytew)))
  (set $end (sub (0x10000) ($offset) ))
  (@while (lt ($adr) ($end)) (
    (store ($adr) (load (add ($adr) ($offset))))
    (set $adr (add ($adr) (4)))
  ))
  (set $end (@call scrnheight))
  (set $px (@call scrnwidth))
  (set $offset (32))
  (@while ($offset) (
    (@call pset ($px) ($end) (load8u (0xaffe)))
    (set $px (sub ($px) (1)))
    (set $offset (sub ($offset) (1)))
  ))
  (@while (lt ($adr) (0xfffc)) (
    (store ($adr) (load (0xfffc)))
    (set $adr (add ($adr) (4)))
  ))
  (@return)
)

(scrndepth:
  (jump (mult (and (3) (load8u (0xb4f8))) (0xb) ))
  ;; modes 0 and 4
  (@return (1))
  ;; modes 1 and 5
  (@return (3))
  ;; modes 2 and 6
  (@return (15))
  ;; modes 3 and 7
  (@return (255))
)

(scrnwidth:
  (jump (mult (and (7) (load8u (0xb4f8))) (0xb) ))
  ;; mode 0
  (@return (511))
  ;; mode 1
  (@return (511))
  ;; mode 2
  (@return (255))
  ;; mode 3
  (@return (255))

  ;; mode 4
  (@return (511))
  ;; mode 5
  (@return (255))
  ;; mode 6
  (@return (255))
  ;; mode 7
  (@return (127))
)

(scrnheight:
  (jump (mult (and (7) (load8u (0xb4f8))) (0xb) ))
  ;; mode 0
  (@return (287))
  ;; mode 1
  (@return (143))
  ;; mode 2
  (@return (143))
  ;; mode 3
  (@return (71))

  ;; mode 4
  (@return (287))
  ;; mode 5
  (@return (287))
  ;; mode 6
  (@return (143))
  ;; mode 7
  (@return (143))
)


(scrnbytew:
  (jump (mult (and (7) (load8u (0xb4f8))) (0xb) ))
  ;; mode 0
  (@return (512/8))
  ;; mode 1
  (@return (512/4))
  ;; mode 2
  (@return (256/2))
  ;; mode 3
  (@return (256/1))

  ;; mode 4
  (@return (512/8))
  ;; mode 5
  (@return (256/4))
  ;; mode 6
  (@return (256/2))
  ;; mode 7
  (@return (128/1))
)


(pow:
  (@vars $a $b $z)
  (set $z (1))
  (@while (gt ($b) (0)) (
    (set $z (mult ($z) ($a)))
    (set $b (sub ($b) (1)))
  ) )
  (@return ($z))
)

(memstart: ;; must be the last function
  (@return (add (8) (here)))
)
;; 0x0
(@string 0x40 "\t /// Peti8\x20 ///\t\t\t /// Peti R ///\n\n\n")
;; 0x40
(@string 0x10 "\nReady.\n")
;; 0x50
(@string 0x20 "0123456789abcdefghijklmnopqrstuvwxyz")
;; 0x70
(@string 0x20 " bytes free.\n")
;; 0x90
(@string 0x100 "{temporary string}")
;; 0x190
(@string 0x20 " ips.\n")
;; 0x1b0
