;; title:  SUPER MINEUR 2026 - Fusion Ultime
;; author: BecVerresoeur & Équipe
;; desc:   ZQSD, Flèches pour miner, Espace pour sauter, R pour Reset
;; script: fennel

;; --- 1. VARIABLES GLOBALES ---
(var state "menu") ;; États: "menu", "play"

;; LE DICTIONNAIRE DES SPRITES (On garde ta version et on ajoute l'échelle de Maxence)
(var ID {
  :joueur 1
  :roche 21
  :roche-spe 22
  :minerai-r 5
  :minerai-v 6
  :monstre 7
  :echelle 8 ;; Nouveau numéro pour l'échelle !
})

(var player {})
(var pool []) 
(var monsters [])

;; --- 2. GÉNÉRATION & RESET ---
(fn init-map []
  (for [x 0 29]
    (for [y 0 16]
      (mset x y ID.roche)))
      
  (for [x 13 16]
    (for [y 1 4]
      (mset x y 0)))
      
  (var placed 0)
  (while (< placed 7)
    (let [rx (math.random 0 29)
          ry (math.random 0 16)]
      (when (= (mget rx ry) ID.roche)
        (mset rx ry ID.roche-spe)
        (set placed (+ placed 1))))))

;; La fonction qui remet TOUT le jeu à zéro
(fn reset-game []
  (init-map)
  ;; On retourne au menu
  (set state "menu")
  ;; On combine les variables de stats et de minage
  (set player { :x 120 :y 20 :vy 0 :gravity 0.2 :speed 1.5 :flip 0 :is-grounded false 
                :hp 100 :fuel 100 :max-fuel 100 :min-r 0 :min-v 0 
                :mining-timer 0 :mining-max 30 :mining-dir nil })
  (set pool [ID.minerai-r ID.minerai-r ID.minerai-r 
             ID.minerai-v ID.minerai-v 
             ID.monstre ID.monstre])
  (set monsters []))

(reset-game)

;; --- 3. FONCTIONS OUTILS ---
(fn get-tile [px py]
  (mget (math.floor (/ px 8)) (math.floor (/ py 8))))

;; Maxence ignore l'échelle, toi tu gardes les roches. On combine :
(fn solid? [t]
  (or (= t ID.roche) (= t ID.roche-spe)))

;; Fusion des Hitboxes : Flexible comme la tienne, 6 points de contrôle comme Maxence !
(fn collide-rect? [x y w h]
  (let [l (+ x 1) r (+ x w -2)
        t (+ y 1) b (+ y h -1)
        mid (+ y (/ h 2))] ;; Le point du milieu pour éviter de passer à travers
    (or (solid? (get-tile l t))   (solid? (get-tile r t))
        (solid? (get-tile l mid)) (solid? (get-tile r mid))
        (solid? (get-tile l b))   (solid? (get-tile r b)))))

(fn ramasser [x y]
  (let [tx (math.floor (/ x 8))
        ty (math.floor (/ y 8))
        t (mget tx ty)]
    (when (= t ID.minerai-r)
      (set player.min-r (+ player.min-r 1))
      (mset tx ty 0)) 
    (when (= t ID.minerai-v)
      (set player.min-v (+ player.min-v 1))
      (mset tx ty 0))))

;; --- LA LOGIQUE DE DESTRUCTION DE BLOC ---
(fn mine-block [tx ty]
  (let [cible (mget tx ty)]
    (when (solid? cible)
      (mset tx ty 0)
      (set player.fuel (- player.fuel 2))
      ;; RNG du bloc spécial
      (when (= cible ID.roche-spe)
        (when (> (length pool) 0)
          (let [idx (math.random 1 (length pool))
                item (. pool idx)]
            (table.remove pool idx)
            (if (or (= item ID.minerai-r) (= item ID.minerai-v))
                (mset tx ty item) 
                (= item ID.monstre)
                (table.insert monsters {:x (* tx 8) :y (* ty 8) :hp 60 :timer 300}))))))))

;; --- 4. ÉCRAN : MENU ---
(fn draw-menu []
  (cls 0)
  (let [t (math.floor (/ (time) 500))
        title "SUPER MINEUR 2026"
        prompt "APPUYEZ SUR ESPACE POUR JOUER"]
    (let [w (print title 0 -20 0 false 2)]
      (print title (/ (- 240 w) 2) 50 12 false 2))
    (when (= (% t 2) 0)
      (let [w (print prompt 0 -20 0)]
        (print prompt (/ (- 240 w) 2) 100 6)))
  (when (key 48) (set state "play"))))

;; --- 5. ÉCRAN : JEU ---
(fn draw-game []
  (cls 13) 

  ;; --- A. GESTION DU MINAGE ET ATTAQUE ---
  (if (btn 0) (set player.mining-dir 0) 
      (btn 1) (set player.mining-dir 1)
      (btn 2) (set player.mining-dir 2) 
      (btn 3) (set player.mining-dir 3)
      (set player.mining-dir nil))

  ;; Si on mine et qu'on a du fuel
  (when (and (not= player.mining-dir nil) (> player.fuel 0))
    (var hit-monster false)
    
    ;; 1. Détection de la zone d'attaque devant le joueur
    (var ax player.x) (var ay player.y) (var aw 16) (var ah 16)
    (if (= player.mining-dir 0) (do (set ay (- player.y 8)) (set ah 8))
        (= player.mining-dir 1) (do (set ay (+ player.y 16)) (set ah 8))
        (= player.mining-dir 2) (do (set ax (- player.x 8)) (set aw 8))
        (= player.mining-dir 3) (do (set ax (+ player.x 16)) (set aw 8)))

    (each [_ m (ipairs monsters)]
      (when (and (< ax (+ m.x 8)) (> (+ ax aw) m.x)
                 (< ay (+ m.y 8)) (> (+ ay ah) m.y))
        (set hit-monster true)
        (set m.hp (- m.hp 1))
        (set player.fuel (- player.fuel 0.5))))

    ;; 2. Si on tape un monstre, la barre s'arrête. Sinon, on creuse !
    (if hit-monster
        (set player.mining-timer 0)
        (do
          (set player.mining-timer (+ player.mining-timer 1))
          (when (>= player.mining-timer player.mining-max)
            (let [t-left (math.floor (/ (+ player.x 3) 8)) 
                  t-right (math.floor (/ (+ player.x 12) 8))
                  t-top (math.floor (/ (+ player.y 2) 8)) 
                  t-bottom (math.floor (/ (+ player.y 14) 8))]
              
              ;; L'astuce est ici : on décale la zone de -4 ou +20 pour forer HORS du joueur !
              (if (= player.mining-dir 0) (for [tx t-left t-right] (mine-block tx (math.floor (/ (- player.y 4) 8))))
                  (= player.mining-dir 1) (for [tx t-left t-right] (mine-block tx (math.floor (/ (+ player.y 20) 8))))
                  (= player.mining-dir 2) (for [ty t-top t-bottom] (mine-block (math.floor (/ (- player.x 4) 8)) ty))
                  (= player.mining-dir 3) (for [ty t-top t-bottom] (mine-block (math.floor (/ (+ player.x 20) 8)) ty))))
            
            (set player.mining-timer 0)))))
            
  ;; Sécurité Fuel et relâchement
  (when (< player.fuel 0) (set player.fuel 0))
  (when (= player.mining-dir nil) (set player.mining-timer 0))

  
  ;; --- B. RAMASSAGE MINERAIS ---
  (ramasser (+ player.x 4) (+ player.y 4))
  (ramasser (+ player.x 12) (+ player.y 4))
  (ramasser (+ player.x 4) (+ player.y 12))
  (ramasser (+ player.x 12) (+ player.y 12))

  ;; --- C. ÉCHELLES (Touche A / Code 01) ---
  (when (keyp 01)
    (let [tx (math.floor (/ (+ player.x 8) 8))
          ty-haut (math.floor (/ (+ player.y 4) 8))
          ty-bas (+ ty-haut 1)]
      (mset tx ty-haut ID.echelle)
      (mset tx ty-bas ID.echelle)))

  ;; --- D. GESTION DES MONSTRES ---
  (for [i (length monsters) 1 -1]
    (let [m (. monsters i)]
      (set m.timer (- m.timer 1))
      
      (var next-my (+ m.y 1))
      (if (collide-rect? m.x next-my 8 8) nil (set m.y next-my)) 
      
      (var next-mx m.x)
      (if (< m.x player.x) (set next-mx (+ m.x 0.5))
          (> m.x player.x) (set next-mx (- m.x 0.5)))
          
      (if (not (collide-rect? next-mx m.y 8 8))
          (set m.x next-mx)
          (if (not (collide-rect? next-mx (- m.y 8) 8 8))
              (do (set m.x next-mx) (set m.y (- m.y 8))))) 
      
      (let [dist-x (math.abs (- player.x m.x)) dist-y (math.abs (- player.y m.y))]
        (when (and (< dist-x 12) (< dist-y 12))
          (set player.hp (- player.hp 0.5))))

      (when (or (<= m.timer 0) (<= m.hp 0))
        (table.remove monsters i))))

  ;; --- E. MOUVEMENTS (ZQSD) ---
  (var dx 0)
  (if (key 17) (set dx (- player.speed))) ;; Q
  (if (key 04) (set dx player.speed))     ;; D
  (when (not= dx 0)
    (if (not (collide-rect? (+ player.x dx) player.y 16 16)) (set player.x (+ player.x dx)))
    (if (< dx 0) (set player.flip 0) (set player.flip 1)))

  ;; --- F. PHYSIQUE & GRAVITÉ ---
  (set player.vy (+ player.vy player.gravity))
  (let [futur-y (+ player.y player.vy)]
    (if (collide-rect? player.x futur-y 16 16)
        (do
          (if (> player.vy 0)
              (do (set player.y (- (* (math.floor (/ (+ futur-y 15) 8)) 8) 16)) (set player.is-grounded true)) 
              (set player.vy 0))
          (set player.vy 0))
        (do (set player.y futur-y) (set player.is-grounded false))))

  ;; --- G. SAUT (Espace) ---
  (when (and (key 48) player.is-grounded)
    (set player.vy -2.5)
    (set player.is-grounded false))

  ;; --- H. AFFICHAGE ---
  (map 0 0 30 17 0 0 0) 
  (spr ID.joueur player.x player.y 0 1 player.flip 0 2 2)
  
  (each [_ m (ipairs monsters)]
    (spr ID.monstre m.x m.y 0)
    (rect m.x (- m.y 6) (* (/ m.hp 60) 8) 2 2)
    (rect m.x (- m.y 3) (* (/ m.timer 300) 8) 2 11))
    
  (when (> player.mining-timer 0)
    (let [bar-w 16 prog (* (/ player.mining-timer player.mining-max) bar-w)]
      (rect player.x (- player.y 6) bar-w 3 0)
      (rect player.x (- player.y 6) prog 3 6)))

  ;; --- UI ---
  (rect 4 4 102 6 0) 
  (rect 4 12 102 6 0) 
  (rect 5 5 (* (/ player.hp 100) 100) 4 2)   
  (rect 5 13 (* (/ player.fuel player.max-fuel) 100) 4 10) 
  
  (print "HP" 110 4 2)
  (print "FUEL" 110 12 10)
  (print (.. "Profondeur: " (math.floor player.y)) 5 125 15)
  (print (.. "Rouge: " player.min-r) 160 5 2)
  (print (.. "Vert: " player.min-v) 205 5 11))

;; --- 6. BOUCLE PRINCIPALE TIC ---
(fn _G.TIC []
  ;; Le Reset Universel sur R (Code 18)
  (when (key 18) (reset-game))

  (if (= state "menu")
      (draw-menu)
      (= state "play")
      (draw-game)))