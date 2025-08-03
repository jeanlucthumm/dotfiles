# Creating New Secrets with Agenix

## Quick Steps

1. **Add secret to `secrets.nix`**:
   ```nix
   "my-new-secret.age".publicKeys = acc; // Uses desktop + macbook keys
   ```

2. **Create the encrypted secret file**:
   ```bash
   cd secrets/
   agenix -e my-new-secret.age
   ```
   This opens your editor to enter the secret content.

3. **Use in configuration**:
   ```nix
   age.secrets.my-new-secret.file = ./secrets/my-new-secret.age;
   ```
   Secret will be available at `/run/agenix/my-new-secret`

4. **Add get-key command** (in `home/modules/security.nix`):
   ```nix
   # In age.secrets block:
   my-new-secret = {
     file = ../../secrets/jeanluc-my-new-secret.age;
     mode = "400";
   };
   
   # In home.packages list:
   (pkgs.writeShellScriptBin "get-key-my-new-secret" (makeKeyGetter s.my-new-secret.path))
   ```

## Available Key Sets
- `acc` = desktop + macbook (current default)  
- `keys.all` = desktop + macbook + phone
- Individual: `keys.desktop`, `keys.macbook`, `keys.phone`

## Useful Commands
- **Edit existing secret**: `agenix -e secret-name.age`
- **Rekey after adding recipients**: `agenix -r secret-name.age`
- **Manual decrypt**: `agenix -d secret-name.age -i ~/.ssh/id_ed25519`