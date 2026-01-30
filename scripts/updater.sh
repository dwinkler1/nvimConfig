echo "📡 Fetching latest R version from rstats-on-nix..."
RVER=$( wget -qO- 'https://raw.githubusercontent.com/ropensci/rix/refs/heads/main/inst/extdata/available_df.csv' | tail -n 1 | head -n 1 | cut -d',' -f4 | tr -d '"' )

# Validate RVER matches YYYY-MM-DD format
if [[ ! "$RVER" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "❌ Error: Failed to fetch valid R version date. Got: '$RVER'"
  exit 1
fi

echo "✅ R date is $RVER"

# Create backup of flake.nix before modifying
cp flake.nix flake.nix.backup

# Update rixpkgs date in flake.nix
if sed -i "s|rixpkgs.url = \"github:rstats-on-nix/nixpkgs/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\";|rixpkgs.url = \"github:rstats-on-nix/nixpkgs/$RVER\";|" flake.nix; then
  echo "✅ Updated rixpkgs date in flake.nix"
  rm flake.nix.backup
else
  echo "⚠️  Warning: Failed to update flake.nix, restoring backup"
  mv flake.nix.backup flake.nix
fi
