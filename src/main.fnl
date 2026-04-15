;; title:  Mineur
;; author: BecVerresoeur
;; desc:   Jeu de minage - Version Corrigée
;; script: fennel

;; --- VARIABLES GLOBALES ---
(var player { :x 120 
              :y 20 
              :vy 0
              :gravity 0.2
              :speed 1.5 
              :flip 0 }) ;; On part sur 0 par défaut

;; --- FONCTIONS OUTILS ---
(fn get-tile [px py]
  (let [tx (math.floor (/ px 8))
        ty (math.floor (/ py 8))]
    (mget tx ty)))

(fn collide? [x y]
  (or (> (get-tile (+ x 3) (+ y 2)) 0)
      (> (get-tile (+ x 12) (+ y 2)) 0)
      (> (get-tile (+ x 3) (+ y 15)) 0)
      (> (get-tile (+ x 12) (+ y 15)) 0)))

;; --- BOUCLE PRINCIPALE ---
(fn _G.TIC []
  (cls 13) 

  ;; 1. PHYSIQUE & GRAVITÉ (Axe Y) - Fix anti-sautillement
  (set player.vy (+ player.vy player.gravity))
  (let [futur-y (+ player.y player.vy)]
    (if (collide? player.x futur-y)
        (do
          (when (> player.vy 0)
            (set player.y (- (* (math.floor (/ (+ futur-y 15) 8)) 8) 16)))
          (set player.vy 0))
        (set player.y futur-y)))

  ;; 2. CONTRÔLES ET MURS (Axe X) - Fix Moonwalk
  (when (btn 2) ;; Gauche
    (let [futur-x (- player.x player.speed)]
      (when (not (collide? futur-x player.y))
        (set player.x futur-x)
        (set player.flip 0)))) ;; Inversé pour corriger le moonwalk
            
  (when (btn 3) ;; Droite
    (let [futur-x (+ player.x player.speed)]
      (when (not (collide? futur-x player.y))
        (set player.x futur-x)
        (set player.flip 1)))) ;; Inversé pour corriger le moonwalk
    
  ;; 3. SAUT - Moins haut
  ;; On a changé -3.5 par -2.5
  (when (and (btn 4) (collide? player.x (+ player.y 1)))
    (set player.vy -2.5)) 

  ;; 4. AFFICHAGE
  (map 0 0 30 17 0 0 0) 
  (spr 1 player.x player.y 0 1 player.flip 0 2 2)
  
  (print "Profondeur:" 5 5 15)
  (print (math.floor player.y) 65 5 12)
);; title:  Mineur - L'Édition Fusion Ultime
;; author: BecVerresoeur & Équipe
;; desc:   Jeu de minage (Physique propre + Souris)
;; script: fennel

;; --- VARIABLES GLOBALES ---
;; On a ajouté le fameux "is-grounded" de ton collègue directement dans le joueur
(var player { :x 120 
              :y 20 
              :vy 0
              :gravity 0.2
              :speed 1.5 
              :flip 0 
              :is-grounded false })

;; --- FONCTIONS OUTILS ---
(fn get-tile [px py]
  (let [tx (math.floor (/ px 8))
        ty (math.floor (/ py 8))]
    (mget tx ty)))

;; Notre hitbox souple (tolérance sur les bords pour ne pas se coincer)
(fn collide? [x y]
  (or (> (get-tile (+ x 3) (+ y 2)) 0)
      (> (get-tile (+ x 12) (+ y 2)) 0)
      (> (get-tile (+ x 3) (+ y 15)) 0)
      (> (get-tile (+ x 12) (+ y 15)) 0)))

;; --- BOUCLE PRINCIPALE ---
(fn _G.TIC []
  (cls 13) 

  ;; 1. GESTION DE LA SOURIS (Le minage du collègue !)
  (var (mx my left-click) (mouse))
  (when left-click
    (var tile-x (math.floor (/ mx 8)))
    (var tile-y (math.floor (/ my 8)))
    ;; mset remplace le bloc cliqué par le bloc 0 (le vide)
    (mset tile-x tile-y 0))

  ;; 2. PHYSIQUE & GRAVITÉ (Axe Y)
  (set player.vy (+ player.vy player.gravity))
  (let [futur-y (+ player.y player.vy)]
    (if (collide? player.x futur-y)
        (do
          (when (> player.vy 0)
            ;; On s'aligne sur le bloc si on tombe
            (set player.y (- (* (math.floor (/ (+ futur-y 15) 8)) 8) 16))
            ;; LE DRAPEAU EST LEVÉ ! On touche le sol.
            (set player.is-grounded true)) 
          (set player.vy 0))
        (do
          ;; Si on ne touche rien, on tombe, donc le drapeau est baissé
          (set player.y futur-y)
          (set player.is-grounded false))))

  ;; 3. CONTRÔLES ET MURS (Axe X)
  (when (btn 2) ;; Gauche
    (let [futur-x (- player.x player.speed)]
      (when (not (collide? futur-x player.y))
        (set player.x futur-x)
        (set player.flip 0)))) ;; À inverser avec 1 si ça fait du moonwalk
            
  (when (btn 3) ;; Droite
    (let [futur-x (+ player.x player.speed)]
      (when (not (collide? futur-x player.y))
        (set player.x futur-x)
        (set player.flip 1)))) ;; À inverser avec 0 si ça fait du moonwalk
    
  ;; 4. SAUT (Sécurisé grâce au drapeau du collègue)
  (when (and (btn 4) player.is-grounded)
    (set player.vy -2.5)
    ;; Dès qu'on saute, on n'est techniquement plus au sol !
    (set player.is-grounded false))

  ;; 5. AFFICHAGE
  (map 0 0 30 17 0 0 0) 
  (spr 1 player.x player.y 0 1 player.flip 0 2 2)
  
  ;; Dessin du curseur de la souris (Code du collègue)
  (circ mx my 2 2)
  
  ;; Interface
  (print "Profondeur:" 5 5 15)
  (print (math.floor player.y) 65 5 12)
)