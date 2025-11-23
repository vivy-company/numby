# TUI interface strings

# Commands help
commands-help = Commandes : :q quitter, :w sauvegarder, :lang [langue] changer langue, :langs lister langues

# Help tooltip
help-commands = Commandes : :q quitter  :w sauvegarder  :w <fichier> sauvegarder sous  :lang changer langue  :langs lister langues
help-shortcuts = Raccourcis : Ctrl+Y copier résultat  Ctrl+I copier entrée  Ctrl+A copier entrée

# Input validation
input-size-limit = Limite de taille d'entrée atteinte ({$max} caractères max)
line-validation-error = Erreur de validation de ligne : {$error}

# File operations
no-file-to-save = Aucun fichier à sauvegarder. Utilisez :w nomfichier
file-saved = Fichier sauvegardé : {$path}
error-saving-file = Erreur lors de la sauvegarde du fichier : {$error}
invalid-file-path = Chemin invalide : {$error}

# Language commands
current-language = Langue actuelle : {$name}
available-languages = Langues disponibles : {$list}
language-changed = Langue changée en : {$name}
failed-set-language = Échec du changement de langue : {$error}

# Pied de page
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = aide

# Aide
tui-help-enter-key = Entrée
tui-help-enter-desc = nouvelle ligne / exécuter
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = sauvegarder (demande si sans nom)
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = quitter
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = copier le markdown partageable
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = copier le résultat courant
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = vider le cache
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = afficher/masquer l'aide
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = sélecteur de format d'heure
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = sélecteur de format de date
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = sélecteur de langue
tui-help-f1-key = F1
tui-help-f1-desc = afficher/masquer l'aide
tui-help-esc-key = Échap
tui-help-esc-desc = fermer l'aide ou la boîte de dialogue

# Sélecteur de langue
tui-locale-title = Langue
tui-locale-footer = ↑/↓ choisir   Entrée appliquer   Échap fermer

# Sélecteur de format
tui-format-time-title = Heure
tui-format-date-title = Date
tui-format-footer = ↑/↓ choisir   ←/→ changer de liste   Entrée appliquer   Échap fermer

# Enregistrement
tui-save-default-filename = untitled.numby
tui-save-label = Enregistrer sous :
tui-save-hint = (Entrée pour enregistrer, Échap pour annuler)

# Messages d'état
tui-format-set-status = Formats définis : heure {$time}, date {$date}
tui-locale-set-status = Langue définie sur {$name}
tui-quit-ctrlc = Appuyez encore sur Ctrl+C pour quitter
tui-quit-esc = Appuyez encore sur Échap pour quitter

# Partage Markdown
markdown-results-heading = ### Résultats
markdown-results-row = - `{$expr}` → `{$result}`
