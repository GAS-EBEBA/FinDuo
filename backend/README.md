# FinDuo API locale

Backend V1 en Node.js/TypeScript + Express + MySQL. Le backend est indépendant de Firebase ; la migration Flutter se fera progressivement et Firebase ne sera retiré qu'après validation de l'ensemble des parcours et données.

## Prérequis

- Node.js 20 ou supérieur
- Serveur MySQL 8 démarré en local (MySQL Workbench est un client, il ne démarre pas à lui seul le serveur)
- Base `finduo` et compte local de moindre privilège `finduo_app`

## Préparer MySQL avec Workbench

1. Démarrer le service MySQL local, puis se connecter avec MySQL Workbench.
2. Ouvrir et exécuter `migrations/001_initial_schema.sql`.
3. Avec un compte d'administration MySQL, créer un utilisateur applicatif local avec un mot de passe choisi par vous et des droits limités :

	```sql
	CREATE USER 'finduo_app'@'127.0.0.1' IDENTIFIED BY 'CHOISIR_UN_MOT_DE_PASSE_LOCAL';
	GRANT SELECT, INSERT, UPDATE, DELETE ON finduo.* TO 'finduo_app'@'127.0.0.1';
	```

	Remplacez le texte du mot de passe avant d'exécuter le SQL. Ne partagez pas ce mot de passe et ne l'ajoutez pas au dépôt. Ne pas utiliser le compte `root` depuis l'API.
4. Copier `.env.example` vers `.env` et renseigner le mot de passe de cet utilisateur dans le fichier local ignoré par Git.

## Installer et démarrer

```sh
npm install
npm run dev
```

- `GET /health` confirme que le processus Node fonctionne.
- `GET /ready` vérifie aussi l'accès MySQL.
- `GET /api/v1/exercises` liste les exercices publiés.
- `GET /api/v1/exercises/:id/video` diffuse une vidéo publiée avec prise en charge des requêtes HTTP Range pour lecture et recherche dans la vidéo.

Pour l'émulateur Android, l'adresse locale de l'hôte est généralement `http://10.0.2.2:3000`. Pour un appareil physique, utilisez l'adresse IP locale du Mac et vérifiez le pare-feu.

Les fichiers envoyés seront stockés dans `storage/uploads/` et ne doivent pas être commités. Aucune route d'administration/téléversement n'est exposée tant qu'une authentification administrateur côté serveur n'est pas implémentée.
