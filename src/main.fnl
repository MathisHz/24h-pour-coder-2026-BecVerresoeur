;; title:  Mineur
;; author: BecVerresoeur
;; desc:   Jeu de minage
;; script: fennel

;; --- VARIABLES GLOBALES ---
;; On fait apparaître le joueur au centre (x=120, y=68)
(var player { :x 120 :y 68 :w 16 :h 16 
              :vy 0 :gravity 0.2 :speed 1.5 :flip 0 })

;; --- BOUCLE PRINCIPALE ---
(fn _G.TIC []
  (cls 9) 
  
  ;; 1. GESTION DE LA SOURIS ET DU MINAGE
  (var (mx my left-click) (mouse))
  (when left-click
    (var tile-x (math.floor (/ mx 8)))
    (var tile-y (math.floor (/ my 8)))
    (mset tile-x tile-y 0))

  ;; 2. PHYSIQUE DE BASE ET GRAVITÉ (Collision Sol)
  (set player.vy (+ player.vy player.gravity))
  (var next-y (+ player.y player.vy))
  
  (var foot-x (math.floor (/ (+ player.x 8) 8))) 
  (var foot-y (math.floor (/ (+ next-y player.h) 8)))
  (var tile-under (mget foot-x foot-y)) 
  
  (var is-grounded false)
  (if (> tile-under 0) 
    (do
      (set next-y (- (* foot-y 8) player.h)) 
      (set player.vy 0)
      (set is-grounded true)))

  (set player.y next-y)

  ;; 3. CONTRÔLES ET COLLISION HORIZONTALE
  (var next-x player.x)

  ;; On calcule l'intention de mouvement
  (when (btn 2) 
    (set player.flip 0)
    (set next-x (- player.x player.speed)))
  (when (btn 3) 
    (set player.flip 1)
    (set next-x (+ player.x player.speed)))
    
  (when (and (btn 4) is-grounded)
    (set player.vy -3.5)) 

  ;; --- LA NOUVELLE MAGIE : LA COLLISION MURALE ---
  ;; Si le joueur essaie de bouger sur l'axe X
  (when (not= next-x player.x)
    (var is-blocked false)
    
    ;; On regarde quel bord du personnage va cogner (gauche ou droite)
    (var edge-x (if (< next-x player.x) 
                next-x                         ;; Bord gauche
                (- (+ next-x player.w) 1)))    ;; Bord droit
    
    ;; On convertit la position en "cases" de la carte
    (var tile-x (math.floor (/ edge-x 8)))
    ;; On vérifie 2 points pour être sûr : le haut de la tête et le bas des pieds
    (var tile-y-top (math.floor (/ player.y 8)))
    (var tile-y-bottom (math.floor (/ (+ player.y player.h -1) 8)))
    
    ;; On lit la carte aux endroits calculés
    (when (or (> (mget tile-x tile-y-top) 0) 
              (> (mget tile-x tile-y-bottom) 0))
      (set is-blocked true)) ;; Un bloc bloque le chemin !
      
    ;; Si aucun bloc n'a été trouvé, on valide le déplacement final
    (when (not is-blocked)
      (set player.x next-x)))

  ;; 4. AFFICHAGE
  (map 0 0 30 17 0 0)
  (spr 1 player.x player.y 0 1 player.flip 0 2 2)
  (circ mx my 2 2)
)