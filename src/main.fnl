;; title:  SUPER MINEUR 2026
;; author: BecVerresoeur
;; desc:   ZQSD pour bouger, Flèches pour miner, A pour échelles, Espace pour sauter
;; script: fennel

;; --- 1. VARIABLES GLOBALES ---
(var state "menu") ;; États possibles : "menu", "play"

(var player { :x 120 
              :y 20 
              :vy 0 
              :gravity 0.2 
              :speed 1.5 
              :flip 0 
              :is-grounded false
              ;; Paramètres de minage
              :mining-timer 0
              :mining-max 30  ;; 0.5 seconde de latence
              :mining-dir nil })

;; --- 2. FONCTIONS OUTILS ---

(fn get-tile [px py]
  (mget (math.floor (/ px 8)) (math.floor (/ py 8))))

;; Un bloc est un mur s'il n'est pas vide (0) ET n'est pas une échelle (2)
(fn is-wall? [px py]
  (let [t (get-tile px py)]
    ;; C'est un mur si l'ID est > 0 ET que ce n'est pas notre échelle (ID 5)
    (and (> t 0) (not= t 5))))

;; Détection de collision sur 6 points (évite de passer à travers les murs/plafonds)
(fn collide? [x y]
  (or (is-wall? (+ x 3) (+ y 2))    (is-wall? (+ x 12) (+ y 2))  ;; Haut
      (is-wall? (+ x 3) (+ y 8))    (is-wall? (+ x 12) (+ y 8))  ;; Milieu
      (is-wall? (+ x 3) (+ y 15))   (is-wall? (+ x 12) (+ y 15)))) ;; Bas

;; --- 3. ÉCRAN : MENU (Centrage Automatique) ---

(fn draw-menu []
  (cls 0)
  (let [t (math.floor (/ (time) 500))
        title "SUPER MINEUR 2026"
        author "Par BecVerresoeur"
        prompt "APPUYEZ SUR ESPACE POUR JOUER"]
    
    ;; Centrage automatique du titre (Scale 2)
    (let [w (print title 0 -20 0 false 2)]
      (print title (/ (- 240 w) 2) 50 12 false 2))

    ;; Centrage de l'auteur
    (let [w (print author 0 -20 0)]
      (print author (/ (- 240 w) 2) 70 15))
    
    ;; Texte clignotant centré
    (when (= (% t 2) 0)
      (let [w (print prompt 0 -20 0)]
        (print prompt (/ (- 240 w) 2) 100 6)))
  
  ;; Lancement du jeu
  (when (key 48) (set state "play"))))

;; --- 4. ÉCRAN : JEU ---

(fn draw-game []
  (cls 13)

  ;; --- A. GESTION DU MINAGE ---
  (if (btn 0) (set player.mining-dir 0) 
      (btn 1) (set player.mining-dir 1)
      (btn 2) (set player.mining-dir 2) 
      (btn 3) (set player.mining-dir 3)
      (set player.mining-dir nil))

  (if (not= player.mining-dir nil)
      (do
        (set player.mining-timer (+ player.mining-timer 1))
        (when (>= player.mining-timer player.mining-max)
          (let [t-left (math.floor (/ (+ player.x 3) 8)) 
                t-right (math.floor (/ (+ player.x 12) 8))
                t-top (math.floor (/ (+ player.y 2) 8)) 
                t-bottom (math.floor (/ (+ player.y 14) 8))]
            ;; Casse directionnelle avec balayage pour éviter les trous
            (if (= player.mining-dir 0) (for [tx t-left t-right] (mset tx (math.floor (/ (- player.y 1) 8)) 0))
                (= player.mining-dir 1) (for [tx t-left t-right] (mset tx (math.floor (/ (+ player.y 16) 8)) 0))
                (= player.mining-dir 2) (for [ty t-top t-bottom] (mset (math.floor (/ player.x 8)) ty 0))
                (= player.mining-dir 3) (for [ty t-top t-bottom] (mset (math.floor (/ (+ player.x 16) 8)) ty 0))))
          (set player.mining-timer 0)))
      (set player.mining-timer 0))

  ;; --- PLACER ÉCHELLE (Touche A / Code 01) ---
  (when (keyp 01)
    (let [tx (math.floor (/ (+ player.x 8) 8))
          ty-haut (math.floor (/ (+ player.y 4) 8))
          ty-bas (+ ty-haut 1)]
      ;; On pose le sprite ID 2 sur la carte [cite: 18]
      (mset tx ty-haut 5)
      (mset tx ty-bas 5)))

  ;; --- C. MOUVEMENTS (ZQSD) ---
  (var dx 0)
  (if (key 17) (set dx (- player.speed))) ;; Q
  (if (key 04) (set dx player.speed))     ;; D
  (when (not= dx 0)
    (if (not (collide? (+ player.x dx) player.y)) (set player.x (+ player.x dx)))
    (if (< dx 0) (set player.flip 1) (set player.flip 0)))

  ;; --- D. PHYSIQUE & GRAVITÉ ---
  (set player.vy (+ player.vy player.gravity))
  (let [futur-y (+ player.y player.vy)]
    (if (collide? player.x futur-y)
        (do 
          (if (> player.vy 0) 
              (do (set player.y (- (* (math.floor (/ (+ futur-y 15) 8)) 8) 16)) (set player.is-grounded true)) 
              (set player.vy 0)) 
          (set player.vy 0))
        (do (set player.y futur-y) (set player.is-grounded false))))

  ;; --- E. SAUT (ESPACE / Code 48) ---
  (when (and (key 48) player.is-grounded) 
    (set player.vy -2.8) 
    (set player.is-grounded false))

  ;; --- F. AFFICHAGE ---
  (map 0 0 30 17 0 0 0)
  (spr 1 player.x player.y 0 1 player.flip 0 2 2)
  
  ;; Barre de minage
  (when (> player.mining-timer 0)
    (let [bar-w 16 prog (* (/ player.mining-timer player.mining-max) bar-w)]
      (rect player.x (- player.y 6) bar-w 3 0)
      (rect player.x (- player.y 6) prog 3 6)))
  
  (print (.. "Profondeur: " (math.floor player.y)) 5 5 15))

;; --- 5. BOUCLE PRINCIPALE TIC ---
(fn _G.TIC []
  (if (= state "menu")
      (draw-menu)
      (= state "play")
      (draw-game)))