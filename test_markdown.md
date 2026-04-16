# 1. En-têtes (Headers)
# Titre H1
## Titre H2
### Titre H3
#### Titre H4
##### Titre H5
###### Titre H6

---

# 2. Styles de Texte (Emphasis)
Le Markdown permet de mettre en valeur du texte très facilement.
Voici du texte en **gras** (ou __gras__), en *italique* (ou _italique_), et en ***gras italique***.
Pour rayer une information, nous utilisons le ~~texte barré~~. 

---

# 3. Listes (Lists)
## Listes à Puces (Unordered)
- Pomme
- Banane
  - Sous-élément banane
    - Sous-sous-élément banane
- Cerise

## Listes Numérotées (Ordered)
1. Étape Une
2. Étape Deux
   1. Sous-étape A
   2. Sous-étape B
3. Étape Trois

## Listes de Tâches (Task Lists)
- [x] Tâche accomplie
- [ ] Tâche à faire
- [ ] Autre tâche à faire

---

# 4. Liens et Images
## Liens
Voici un [Lien vers Google](https://google.com "Titre Google").
Et voici un lien de référence [Apple][apple_ref].

[apple_ref]: https://apple.com "Le site d'Apple"

## Images
![Image test](https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg "Logo Apple")

---

# 5. Citations (Blockquotes)
Les citations peuvent être simples ou imbriquées :

> "La folie, c'est de faire toujours la même chose et de s'attendre à un résultat différent."
> - *Peut-être Einstein*
>> Ceci est une citation imbriquée.
>>> Encore plus profond.

---

# 6. Tableaux (Tables)
Le support des tableaux permet d'afficher de la donnée structurée, avec différentes options d'alignement.

| Produit Géré | Prix (Aligné à droite) | Quantité (Centré) |
| :--- | ---: | :---: |
| MacBook Air M3 | 1299 € | 12 |
| iPhone 15 Pro Max | 1479 € | 34 |
| Magic Mouse | 85 € | 200 |

---

# 7. Code (Code Blocks)
Du code `inline` entouré de simples backticks.

Un bloc de code complet avec coloration syntaxique (Swift par exemple) :

```swift
import Foundation

func sayHello(to name: String) {
    print("Bonjour, \(name)!")
}

sayHello(to: "MdView")
```

Un bloc de code Python :
```python
def fibonacci(n):
    if n <= 1: return n
    return fibonacci(n-1) + fibonacci(n-2)
```

---

# 8. Équations (Math / LaTeX)
Grâce à KaTeX, nous pouvons gérer de véritables formules mathématiques très complexes.

**Équation en ligne :** La célèbre formule de masse-énergie est $E = mc^2$. Une autre formule est $a^2 + b^2 = c^2$.

**Équation en bloc (Affichage large) :**
Voici la formule quadratique affichée en bloc :
$$
x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
$$

Et une intégrale complexe :
$$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$

---

# 9. HTML Brut (HTML Blocks)
Vous pouvez insérer des balises HTML si nécessaire.
<details>
<summary>Cliquez pour étendre ce menu HTML caché</summary>
Wahou ! Ce texte était caché dans un menu déroulant HTML natif !
</details>

---

# 10. Filet de séparation
Vous avez déjà vu les `---`, on peut aussi utiliser `***` ou `___` :

***

Fin du fichier de test exhaustif.
