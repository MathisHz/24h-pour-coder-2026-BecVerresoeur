;; title:  Expédition Félicien - Fusion Ultime Finale
;; author: BecVerresoeur & Équipe
;; desc:   Multilevel, Boutique Visuelle, HUD Complet, Difficulté progressive
;; script: fennel

;; --- 1. VARIABLES GLOBALES ---
(var state "menu") ;; États: "menu", "play", "gameover", "shop", "win"
(var current-level 1)
(var map-offset-y 0) 

;; LE DICTIONNAIRE DES CORRESPONDANCES (Roche -> [Orange, Vert, Rouge])
(var TILE_MAP {
  5  {:o 8  :v 11 :r 69}  ;; Coin Haut Gauche
  6  {:o 9  :v 12 :r 70}  ;; Bordure Haut
  7  {:o 10 :v 13 :r 71}  ;; Coin Haut Droit
  21 {:o 24 :v 27 :r 85}  ;; Bordure Gauche
  22 {:o 25 :v 28 :r 86}  ;; Centre / Plein
  23 {:o 26 :v 29 :r 87}  ;; Bordure Droite
  37 {:o 40 :v 43 :r 101} ;; Coin Bas Gauche
  38 {:o 41 :v 44 :r 102} ;; Bordure Bas
  39 {:o 42 :v 45 :r 103} ;; Coin Bas Droit
  53 {:o 25 :v 28 :r 86}  ;; Roche Centre 2
})

(var ID {
  :joueur 256
  :minerai-o 57  
  :minerai-v 60  
  :minerai-r 118 
  :monstre 268
  :monstre-spawn 64 
  :echelle 33
  :echelle-top 32
  :stfelicien 255
  
  ;; TES NOUVEAUX IDs :
  :foreuse-fermee 198   
  :foreuse-ouverte 192  
})

(var player {})
(var monsters [])
(var shop-cursor 0)

;; --- 2. OUTILS DE BASE & CARTE ---

(fn get-map [x y] 
  (or (mget x (+ y map-offset-y)) 0))

(fn set-map [x y v] 
  (mset x (+ y map-offset-y) v))

(fn is-normal-rock? [t]
  (not= (. TILE_MAP t) nil))

(fn is-ore-block? [t]
  (var found false)
  (each [_ res (pairs TILE_MAP)]
    (when (or (= t res.o) (= t res.v) (= t res.r))
      (set found true)))
  found)

(fn is-unbreakable-rock? [t]
  (or (= t 126) (= t 127) (= t 142) (= t 143) (= t 158)))

(fn is-fuel? [t]
  (let [tuile (or t 0)]
    (or (and (>= tuile 96) (<= tuile 98))
        (and (>= tuile 112) (<= tuile 114)))))

(fn get-tile [px py]
  (get-map (math.floor (/ px 8)) (math.floor (/ py 8))))

(fn solid? [t]
  (or (is-normal-rock? t) (is-ore-block? t) (is-unbreakable-rock? t)))

;; --- 3. GÉNÉRATION & RESET ---

(fn start-level []
  (set map-offset-y (* (- current-level 1) 17))
  (sync 4 0 false)

  
  ;; --- NOUVEAUTÉ : GÉNÉRATION DYNAMIQUE DES MINERAIS ---
  (var types-to-place ["o" "o" "o" "v" "v"])
  (if (= current-level 2) (set types-to-place ["o" "o" "v" "v" "r"])
      (>= current-level 3) (set types-to-place ["o" "v" "v" "r" "r"]))
      
  (var placed 0)
  
  (set player.drill-tx nil)
  (set player.drill-ty nil)
  (set player.foreuse-ouverte false)
  
  (for [x 0 29]
    (for [y 0 16]
      (let [current-tile (get-map x y)]
        
        ;; 1. On cherche la foreuse (Sécurité: on accepte la 198 ET la 192)
        (when (or (= current-tile ID.foreuse-fermee) (= current-tile ID.foreuse-ouverte))
          (set player.drill-tx x)
          (set player.drill-ty y))
          
        ;; 2. Les monstres (Difficulté augmentée lvl 3+)
        (when (= current-tile ID.monstre-spawn)
          (set-map x y 0)
          (set-map (+ x 1) y 0)
          (set-map x (+ y 1) 0)
          (set-map (+ x 1) (+ y 1) 0)
          (let [m-hp (if (>= current-level 3) 120 60)]
            (table.insert monsters {:x (* x 8) :y (* y 8) :hp m-hp :max-hp m-hp :timer 99999 :max-timer 99999 :attack-timer 0 :anim-timer 0})))
          
        ;; 3. Les minerais
        (when (and (< placed 5) (is-normal-rock? current-tile))
          (when (= (math.random 1 10) 1)
            (let [type (. types-to-place (+ placed 1))
                  new-tile (. (. TILE_MAP current-tile) type)]
              (set-map x y new-tile)
              (set placed (+ placed 1))))))))
              
  (when (< placed 5)
    (for [x 0 29]
      (for [y 0 16]
        (let [current-tile (get-map x y)]
          (when (and (< placed 5) (is-normal-rock? current-tile))
            (let [type (. types-to-place (+ placed 1))
                  new-tile (. (. TILE_MAP current-tile) type)]
              (set-map x y new-tile)
              (set placed (+ placed 1))))))))
              
  (set player.x 120)
  (set player.y 70) 
  (set player.vy 0)
  (set player.is-grounded false)

  (set player.mining-dir nil)
  (set player.mining-timer 0)
  
  (set player.music-timer 450) ;; <--- AJOUT : 15 secondes (900 images)
  (set monsters [])
  
  ;; Restauration des statistiques inter-niveaux
  (set player.hp 100)
  (set player.fuel player.max-fuel) 
  (set player.ladders 10)
  (music 0 -1 -1 true)) ;; <--- Lancement de la musique en boucle

(fn reset-game []
  (set current-level 1)
  (set shop-cursor 0)
  (set player { :x 120 :y 70 :vy 0 :gravity 0.2 :speed 1.5 :flip 0 :is-grounded false 
                :hp 100 :fuel 100 :max-fuel 100 :min-o 0 :min-v 0 :min-r 0
                :mining-timer 0 :mining-max 30 :mining-dir nil
                :upg-mine 1 :upg-fuel 1 :upg-dmg 1 :dmg 1
                :ladders 10 :anim-timer 0 :is-moving false
                :foreuse-ouverte false :drill-tx nil :drill-ty nil })
  (start-level)
  (set state "menu"))

(reset-game)

;; --- 4. OUTILS DE JEU AVANCÉS ---

(fn collide-rect? [x y w h]
  (let [l (+ x 1) r (+ x w -2) t (+ y 1) b (+ y h -1) mid (+ y (/ h 2))] 
    (or (solid? (get-tile l t))   (solid? (get-tile r t))
        (solid? (get-tile l mid)) (solid? (get-tile r mid))
        (solid? (get-tile l b))   (solid? (get-tile r b)))))

(fn on-ladder? []
  (let [tx (math.floor (/ (+ player.x 8) 8))
        ty (math.floor (/ (+ player.y 8) 8))]
    (or (= (get-map tx ty) ID.echelle) (= (get-map tx ty) ID.echelle-top))))

(fn touch-drill? []
  (var touching false)
  (when (not= player.drill-tx nil)
    (let [px (math.floor (/ (+ player.x 8) 8))
          py (math.floor (/ (+ player.y 8) 8))]
      (when (and (>= px player.drill-tx) (<= px (+ player.drill-tx 4))
                 (>= py player.drill-ty) (<= py (+ player.drill-ty 3)))
        (set touching true))))
  touching)

(fn ramasser [x y]
  (let [tx (math.floor (/ x 8))
        ty (math.floor (/ y 8))
        t (get-map tx ty)]
    (when (= t ID.minerai-o) (set player.min-o (+ player.min-o 1)) (set-map tx ty 0) (sfx 14)) ;; <-- ICI
    (when (= t ID.minerai-v) (set player.min-v (+ player.min-v 1)) (set-map tx ty 0) (sfx 14)) ;; <-- ICI
    (when (= t ID.minerai-r) (set player.min-r (+ player.min-r 1)) (set-map tx ty 0) (sfx 14)) ;; <-- ICI

    (when (= t ID.stfelicien)
      (set-map tx ty 0)
      (when (= current-level 4)
        (set state "win")))

    (when (is-fuel? t) 
      (set player.fuel (+ player.fuel 30))
      (when (> player.fuel player.max-fuel) (set player.fuel player.max-fuel))
      (set-map tx ty 0)
      (sfx 14)))) ;; <-- ICI

(fn count-minerals []
  (var count 0)
  (for [x 0 29]
    (for [y 0 16]
      (let [t (get-map x y)]
        (when (or (is-ore-block? t) 
                  (= t ID.minerai-o) (= t ID.minerai-v) (= t ID.minerai-r))
          (set count (+ count 1))))))
  count)

(fn count-ores []
  (var count 0)
  (for [x 0 29]
    (for [y 0 16]
      (let [t (get-map x y)]
        (when (or (is-normal-rock? t) (is-ore-block? t)
                  (= t ID.minerai-o) (= t ID.minerai-v) (= t ID.minerai-r))
          (set count (+ count 1))))))
  count)

(fn mine-block [tx ty]
  (let [t (get-map tx ty)]
    (when (and (solid? t) (not (is-unbreakable-rock? t)))
      (set player.fuel (- player.fuel 1))
      (sfx 1) ;; <--- AJOUT ICI (Son de casse de bloc)
      
      (when (<= (math.random 1 100) 5)
        (for [ox 0 1] 
          (for [oy 0 1] 
            (let [boom-t (get-map (+ tx ox) (+ ty oy))]
              (when (and (solid? boom-t) (not (is-unbreakable-rock? boom-t))) 
                (set-map (+ tx ox) (+ ty oy) 0)))))
        ;; --- NOUVEAUTÉ : Monstres plus résistants au minage (Niveau 3+) ---
        (let [m-hp (if (>= current-level 3) 120 60)]
          (table.insert monsters {:x (* tx 8) :y (* ty 8) :hp m-hp :max-hp m-hp :timer 300 :max-timer 300 :attack-timer 0 :anim-timer 0})))

      (var dropped false)
      (each [_ res (pairs TILE_MAP)]
        (when (not dropped)
          (if (= t res.o) (do (set-map tx ty ID.minerai-o) (set dropped true))
              (= t res.v) (do (set-map tx ty ID.minerai-v) (set dropped true))
              (= t res.r) (do (set-map tx ty ID.minerai-r) (set dropped true)))))
              
      (when (not dropped)
        (set-map tx ty 0)))))

;; --- 5. ÉCRANS ANNEXES ---

(fn draw-menu []
  (cls 0)
  (let [t (math.floor (/ (time) 500)) title "Expedition Felicien" prompt "APPUYEZ SUR ESPACE POUR JOUER"]
    (let [w (print title 0 -20 0 false 2)] (print title (/ (- 240 w) 2) 50 12 false 2))
    (when (= (% t 2) 0) (let [w (print prompt 0 -20 0)] (print prompt (/ (- 240 w) 2) 100 6)))
  (when (keyp 48) 
    (set state "play")))) ;; <--- ON A ENLEVÉ LA MUSIQUE ICI

(fn draw-shop []
  (cls 0)
  
  (if (btnp 0) (set shop-cursor (- shop-cursor 1)))
  (if (btnp 1) (set shop-cursor (+ shop-cursor 1)))
  (set shop-cursor (% (+ shop-cursor 4) 4)) 

  (when (or (keyp 50) (keyp 48))
    (if 
      (= shop-cursor 0)
      (when (and (< player.upg-mine 5) (>= player.min-o player.upg-mine))
        (set player.min-o (- player.min-o player.upg-mine))
        (set player.upg-mine (+ player.upg-mine 1))
        (set player.mining-max (- 35 (* player.upg-mine 5))))
      (= shop-cursor 1)
      (when (and (< player.upg-fuel 5) (>= player.min-v player.upg-fuel))
        (set player.min-v (- player.min-v player.upg-fuel))
        (set player.upg-fuel (+ player.upg-fuel 1))
        (set player.max-fuel (+ 50 (* player.upg-fuel 50))))
      (= shop-cursor 2)
      (when (and (< player.upg-dmg 2) (>= player.min-r player.upg-dmg))
        (set player.min-r (- player.min-r player.upg-dmg))
        (set player.upg-dmg (+ player.upg-dmg 1))
        (set player.dmg 2))
      (= shop-cursor 3)
      (do
        (set current-level (+ current-level 1))
        (if (> current-level 4)
            (set state "win")
            (do
              (start-level)
              (set state "play")))))) 

  ;; Panneau principal
  (rect 10 10 220 136 5)
  (rect 11 11 218 134 0)

  ;; En-tête dynamique
  (let [header_text (.. "BOUTIQUE - FIN DU NIVEAU " current-level)
        w (print header_text 0 -20 0)] 
    (print header_text (/ (- 240 w) 2) 18 12))
  (line 11 28 228 28 5)

  ;; Ressources (Alignées)
  (spr ID.minerai-r 15 34 0 1 0 0 1 1)
  (print (.. "x " player.min-r) 25 34 15)
  (spr ID.minerai-o 90 34 0 1 0 0 1 1)
  (print (.. "x " player.min-o) 100 34 15)
  (spr ID.minerai-v 170 34 0 1 0 0 1 1)
  (print (.. "x " player.min-v) 180 34 15)

  ;; Améliorations
  (local upgrades [
    {:name "Moteur Foreuse" :current-lvl player.upg-mine :max-lvl 5 :cost-spr ID.minerai-o :logo-spr 48}
    {:name "Reservoir Fuel" :current-lvl player.upg-fuel :max-lvl 5 :cost-spr ID.minerai-v :logo-spr 50}
    {:name "Lames Foreuse" :current-lvl player.upg-dmg :max-lvl 2 :cost-spr ID.minerai-r :logo-spr 49}
  ])

  (for [i 0 2]
    (let [upg (. upgrades (+ i 1))
          y_pos (+ 60 (* i 20))
          is_selected (= shop-cursor i)
          text_color (if is_selected 15 5)]
      (rect 11 y_pos 218 18 (if is_selected 1 0))
      (spr upg.logo-spr 15 (+ y_pos 5) 0 1 0 0 1 1)
      (print (.. upg.name " Lvl " upg.current-lvl) 28 (+ y_pos 6) text_color)

      (if (< upg.current-lvl upg.max-lvl)
          (let [cost_text (.. "x " upg.current-lvl)]
            (spr upg.cost-spr 180 (+ y_pos 5) 0 1 0 0 1 1)
            (print cost_text 190 (+ y_pos 6) text_color))
          (print "MAX" 180 (+ y_pos 6) (if is_selected 12 5)))))

  ;; Quitter (Passage au niveau suivant)
  (let [exit_y_pos (+ 60 (* 3 20))
        is_selected (= shop-cursor 3)]
    (rect 11 exit_y_pos 218 18 (if is_selected 1 0))
    (print ">> NIVEAU SUIVANT >>" 28 (+ exit_y_pos 6) (if is_selected 15 2))))

(fn draw-gameover []
  (cls 0)
  (let [t (math.floor (/ (time) 500)) title "GAME OVER" prompt "APPUYEZ SUR 'R' POUR RECOMMENCER"
        stats1 (.. "Profondeur atteinte : " (math.floor player.y))
        stats2 (.. "Minerais recoltes : " (+ player.min-o player.min-v player.min-r))]
    (let [w (print title 0 -20 0 false 3)] (print title (/ (- 240 w) 2) 30 2 false 3))
    (let [w1 (print stats1 0 -20 0)] (print stats1 (/ (- 240 w1) 2) 70 15))
    (let [w2 (print stats2 0 -20 0)] (print stats2 (/ (- 240 w2) 2) 85 15))
    (when (= (% t 2) 0) (let [w (print prompt 0 -20 0)] (print prompt (/ (- 240 w) 2) 115 6)))))

(fn draw-win []
  (cls 0)
  (let [t (math.floor (/ (time) 500)) title "BRAVO !" msg "JEU TERMINE !" prompt "APPUYEZ SUR ESPACE POUR REJOUER"]
    (let [w (print title 0 -20 0 false 3)] (print title (/ (- 240 w) 2) 40 11 false 3))
    (let [w (print msg 0 -20 0)] (print msg (/ (- 240 w) 2) 75 15))
    (when (= (% t 2) 0) (let [w (print prompt 0 -20 0)] (print prompt (/ (- 240 w) 2) 110 6)))
  (when (key 48) (reset-game))))

;; --- 6. BOUCLE DE JEU PRINCIPALE ---

(fn draw-game []
  (cls 0) 
  
  (set player.anim-timer (+ player.anim-timer 1))

  ;; --- AJOUT : Compte à rebours de la musique ---
  (when (> player.music-timer 0)
    (set player.music-timer (- player.music-timer 1))
    (when (= player.music-timer 0)
      (music -1))) ;; Coupe la musique à 0

  ;; A. GESTION DU MINAGE
  (if (btn 0) (set player.mining-dir 0) 
      (btn 1) (set player.mining-dir 1)
      (btn 2) (set player.mining-dir 2) 
      (btn 3) (set player.mining-dir 3)
      (set player.mining-dir nil))

  (when (and (not= player.mining-dir nil) (> player.fuel 0))
    (var hit-m false)
    (var ax player.x) (var ay player.y) (var aw 16) (var ah 16)
    (if (= player.mining-dir 0) (do (set ay (- player.y 8)) (set ah 8))
        (= player.mining-dir 1) (do (set ay (+ player.y 16)) (set ah 8))
        (= player.mining-dir 2) (do (set ax (- player.x 8)) (set aw 8))
        (= player.mining-dir 3) (do (set ax (+ player.x 16)) (set aw 8)))

    (each [_ m (ipairs monsters)]
      (when (and (< ax (+ m.x 16)) (> (+ ax aw) m.x) (< ay (+ m.y 16)) (> (+ ay ah) m.y))
        (set hit-m true)
        (set m.hp (- m.hp player.dmg))
        (set player.fuel (- player.fuel 0.1))))

    (if hit-m
        (set player.mining-timer 0)
        (do
          (set player.mining-timer (+ player.mining-timer 1))
          (when (>= player.mining-timer player.mining-max)
            (let [t-l (math.floor (/ (+ player.x 3) 8)) t-r (math.floor (/ (+ player.x 12) 8))
                  t-t (math.floor (/ (+ player.y 2) 8)) t-b (math.floor (/ (+ player.y 14) 8))]
              (if (= player.mining-dir 0) (for [tx t-l t-r] (mine-block tx (math.floor (/ (- player.y 4) 8))))
                  (= player.mining-dir 1) (for [tx t-l t-r] (mine-block tx (math.floor (/ (+ player.y 20) 8))))
                  (= player.mining-dir 2) (for [ty t-t t-b] (mine-block (math.floor (/ (- player.x 4) 8)) ty))
                  (= player.mining-dir 3) (for [ty t-t t-b] (mine-block (math.floor (/ (+ player.x 20) 8)) ty))))
            (set player.mining-timer 0)))))
            
  (when (<= player.fuel 0) 
    (set player.fuel 0)
    (if (> (count-ores) 0) 
        (do
          (set state "gameover")
          (music -1) ;; <--- AJOUT ICI
          (sfx 8)))) ;; <--- AJOUT ICI
        
  (when (= player.mining-dir nil) (set player.mining-timer 0))
  
  ;; B. RAMASSAGE & ÉCHELLES
  (ramasser (+ player.x 4) (+ player.y 4))
  (ramasser (+ player.x 12) (+ player.y 4))
  (ramasser (+ player.x 4) (+ player.y 12))
  (ramasser (+ player.x 12) (+ player.y 12))

  (when (and (keyp 01) (> player.ladders 0))
    (let [tx (math.floor (/ (+ player.x 8) 8))
          ty-h (math.floor (/ (+ player.y 4) 8))
          ty-b (+ ty-h 1)
          ty-t (- ty-h 1)]
      (when (not= (get-map tx ty-h) ID.echelle)
        (set-map tx ty-h ID.echelle)
        (set-map tx ty-b ID.echelle)
        (when (= (get-map tx ty-t) 0) (set-map tx ty-t ID.echelle-top))
        (set player.ladders (- player.ladders 1))
        (sfx 2)))) ;; <--- AJOUT ICI

  ;; C. GESTION DES MONSTRES
  (for [i (length monsters) 1 -1]
    (let [m (. monsters i)]
      (set m.timer (- m.timer 1))
      (set m.anim-timer (+ m.anim-timer 1))
      
      (if (> m.attack-timer 0) (set m.attack-timer (- m.attack-timer 1)))
      
      (var n-my (+ m.y 1))
      (if (collide-rect? m.x n-my 16 16) nil (set m.y n-my)) 
      
      (var n-mx m.x)
      (if (< m.x player.x) (set n-mx (+ m.x 0.5)) (> m.x player.x) (set n-mx (- m.x 0.5)))
          
      (let [dx (math.abs (- n-mx player.x)) dy (math.abs (- m.y player.y))]
        (when (and (< dx 16) (< dy 16)) (set n-mx m.x)))
          
      (if (not (collide-rect? n-mx m.y 16 16))
          (set m.x n-mx)
          (if (not (collide-rect? n-mx (- m.y 8) 16 16))
              (do (set m.x n-mx) (set m.y (- m.y 8))))) 
      
      (let [dx (math.abs (- player.x m.x)) dy (math.abs (- player.y m.y))]
        (when (and (< dx 16) (< dy 16))
          (when (<= m.attack-timer 0)
            (let [dmg (if (>= current-level 3) 20 10)]
              (set player.hp (- player.hp dmg)))
            (set m.attack-timer 90)
            (sfx 6)))) ;; <--- AJOUT ICI

      (when (or (<= m.timer 0) (<= m.hp 0))
        (table.remove monsters i))))

  ;; D. MOUVEMENTS & PHYSIQUE
  (var dx 0)
  (if (key 17) (set dx (- player.speed))) 
  (if (key 04) (set dx player.speed))     
  
  (set player.is-moving (not= dx 0))
  
  (when (not= dx 0)
    (if (not (collide-rect? (+ player.x dx) player.y 16 16)) (set player.x (+ player.x dx)))
    (if (< dx 0) (set player.flip 1) (set player.flip 0)))

  (if (and (on-ladder?) (key 26))
      (set player.vy -1.5) 
      (set player.vy (+ player.vy player.gravity))) 

  (let [futur-y (+ player.y player.vy)]
    (if (collide-rect? player.x futur-y 16 16)
        (do
          (if (> player.vy 0)
              (do 
                ;; CORRECTION ICI : Ne joue le son que si on tombe assez vite !
                (when (and (not player.is-grounded) (> player.vy 1.0)) (sfx 3)) 
                (set player.y (- (* (math.floor (/ (+ futur-y 15) 8)) 8) 16)) 
                (set player.is-grounded true)) 
              (set player.vy 0))
          (set player.vy 0))
        (do (set player.y futur-y) (set player.is-grounded false))))

  (when (and (key 48) player.is-grounded)
    (set player.vy -2.5)
    (set player.is-grounded false)
    (sfx 0)) ;; Son de saut

  ;; E. AFFICHAGE CARTE & SPRITES
  (map 0 map-offset-y 30 17 0 0 0) 
  
  (var p-sprite ID.joueur)
  (if (not= player.mining-dir nil)
      (let [f (% (math.floor (/ player.anim-timer 10)) 2)]
        (set p-sprite (if (= f 0) 258 260)))
      player.is-moving
      (let [f (% (math.floor (/ player.anim-timer 10)) 3)]
        (set p-sprite (if (= f 0) 262 (= f 1) 264 266))) 
      (set p-sprite 256)) 

  (spr p-sprite player.x player.y 0 1 player.flip 0 2 2)
  
  (each [_ m (ipairs monsters)]
    (let [speed (if (> m.attack-timer 0) 45 15) 
          frame (math.floor (/ m.anim-timer speed))
          cur-id (if (= (% frame 2) 0) 268 270) 
          m-flip (if (< m.x player.x) 1 0)]
      (spr cur-id m.x m.y 0 1 m-flip 0 2 2))
    ;; --- NOUVEAUTÉ : Jauge de vie adaptée dynamiquement aux max-hp ---
    (rect m.x (- m.y 6) (* (/ m.hp m.max-hp) 16) 2 2)
    (rect m.x (- m.y 3) (* (/ m.timer m.max-timer) 16) 2 11))
    
  (when (> player.mining-timer 0)
    (let [bar-w 16 prog (* (/ player.mining-timer player.mining-max) bar-w)]
      (rect player.x (- player.y 6) bar-w 3 0)
      (rect player.x (- player.y 6) prog 3 11))) 

  ;; --- F. INTERFACE (UI JOLIE) ---
  (rect 0 0 240 15 0) ;; HUD Noir agrandi
  
  (rect 4 2 52 5 5) 
  (rect 4 8 52 5 5) 
  (rect 5 3 (* (/ player.hp 100) 50) 3 9)   
  (rect 5 9 (* (/ player.fuel player.max-fuel) 50) 3 10) 
  
  (print "HP" 60 2 2 false 1 true)
  (print "FUEL" 60 8 10 false 1 true)
  
  (print (.. "Niveau: " current-level "/4") 100 2 15 false 1 true)
  (print (.. "Echelles: " player.ladders) 100 8 15 false 1 true)
  
  (print (.. "Orange: " player.min-o) 170 2 2 false 1 true)
  (print (.. "Vert: " player.min-v) 170 8 5 false 1 true)
  (print (.. "Rouge: " player.min-r) 210 2 11 false 1 true)

  ;; --- G. GESTION DE LA FOREUSE ---
  (let [total-ramasse (+ player.min-o player.min-v player.min-r)]
    (when (and (= (count-minerals) 0) (> total-ramasse 0)) 
      
      ;; Ouvre la foreuse en utilisant les coordonnées sauvegardées
      (when (not player.foreuse-ouverte)
        (set player.foreuse-ouverte true)
        (when (not= player.drill-tx nil)
          (for [ox 0 4]
            (for [oy 0 3]
              (set-map (+ player.drill-tx ox) (+ player.drill-ty oy) (+ ID.foreuse-ouverte ox (* oy 16)))))))
            
      ;; Fait clignoter le message
      (when (= (% (math.floor (/ (time) 200)) 2) 0)
        (print "RETOURNEZ A LA FOREUSE !" 65 30 10 false 1 true))
        
      ;; Collision pour changer de niveau
      (when (touch-drill?)
        (set state "shop"))))

  (when (<= player.hp 0) 
    (do
      (set state "gameover")
      (music -1)  ;; <--- AJOUT ICI
      (sfx 8))))  ;; <--- AJOUT ICI

;; --- 7. BOUCLE PRINCIPALE TIC ---
(fn _G.TIC []
  (when (key 18) (reset-game))

  (if (= state "menu") (draw-menu)
      (= state "play") (draw-game)
      (= state "shop") (draw-shop)
      (= state "gameover") (draw-gameover)
      (= state "win") (draw-win)))