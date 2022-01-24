;;cyber asm

;; requires kernal at 0x400

(main:
  (@vars $argv
    $i)
  ;; (store8 (0xb282) (2)) ;; text bg color
  (store8 (0xb283) (-1)) ;; text fg color
  
  (sys (0x12) (0x48) (0x400) (2)) ;; H
  (sys (0x12) (0x65) (0x400) (2)) ;; e
  (sys (0x12) (0x6c) (0x400) (2)) ;; l
  (sys (0x12) (0x6c) (0x400) (2)) ;; l
  (sys (0x12) (0x6f) (0x400) (2)) ;; o
  (sys (0x12) (0x20) (0x400) (2)) ;;  (space)
  (sys (0x12) (0x57) (0x400) (2)) ;; W
  (sys (0x12) (0x6f) (0x400) (2)) ;; o
  (sys (0x12) (0x72) (0x400) (2)) ;; r
  (sys (0x12) (0x6c) (0x400) (2)) ;; l
  (sys (0x12) (0x64) (0x400) (2)) ;; d
  (sys (0x12) (0x21) (0x400) (2)) ;; !
  (sys (0x12) (0x0a) (0x400) (2)) ;; \n

  (set $i (256))
  (@while ($i) (
    (sys (0x12) (0x09) (0x400) (2)) ;;  (tab)
    (sys (0x12) (0x48) (0x400) (2)) ;; H
    (sys (0x12) (0x65) (0x400) (2)) ;; e
    (sys (0x12) (0x6c) (0x400) (2)) ;; l
    (sys (0x12) (0x6c) (0x400) (2)) ;; l
    (sys (0x12) (0x6f) (0x400) (2)) ;; o
    (sys (0x12) (0x20) (0x400) (2)) ;;  (space)
    (sys (0x12) (0x57) (0x400) (2)) ;; W
    (sys (0x12) (0x6f) (0x400) (2)) ;; o
    (sys (0x12) (0x72) (0x400) (2)) ;; r
    (sys (0x12) (0x6c) (0x400) (2)) ;; l
    (sys (0x12) (0x64) (0x400) (2)) ;; d
    (sys (0x12) (0x21) (0x400) (2)) ;; !
    (set $i (sub ($i) (1)))
  ))

  (@while (lt ($i) (memsize)) (
    (sys (0x12) (load8u ($i)) (0x400) (2))
    (set $i (add ($i) (1)))
  ))


  (@return (0)) ;; return to dos with no error
)