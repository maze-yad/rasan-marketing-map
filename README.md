# Rasan Marketing Map

Rasan's annual marketing plan as an editable mind map, with a budget ledger for every section.

**Live site:** https://maze-yad.github.io/rasan-marketing-map/

## What it does

- **Mind map**: the 7 layers of the plan (Strategy & Campaigns, ATL, OOH, BTL, Trade Marketing, Digital, CSR) with their branches and topics. Click any box to rename, drop, move or delete it. Use the **+** next to any box to add a branch under it, at any depth.
- **Budget**: planned and spent amounts for every branch and topic. Totals add up from sub-topic to topic to branch to layer. Dropped topics are left out. Set the annual budget and currency at the top, and export everything as CSV.

## Where the data lives

Changes save in the browser of the person making them. Use **Export backup** to save the plan as a `.json` file and **Import backup** to load it on another computer or share it with a colleague.

The map that loads for a first-time visitor is the starting plan built into `index.html`.

## Updating the site

The whole site is the single file `index.html`. Replace it and push to `main`; GitHub Pages republishes within a minute or two.
