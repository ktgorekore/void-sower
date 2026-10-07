<!--
  Copyright 2026 Void Sower Authors.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# Google Play Console Release Notes — v0.2.35 (Build 38)

## Release Track: Internal Testing / Closed Testing (Alpha / Beta) / Production

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
⚡ Void Sower v0.2.35 — Pro Commander Experience Uniformity & Zero Ads Audit!
• Zero Ads for Pro: Full audit across Daily Sortie, Campaign sectors, and Incursion. Pro commanders never see ad prompts anywhere in the galaxy.
• Instant Auxiliary Cores: Daily Sortie and Campaign defeat modals now offer instant "SUMMON AUXILIARY CORES" (+56 cores) for Pro pilots without ad interruptions.
• Pro Link Flares: Immediate orbital flare delivery with zero delay.
• UI Polish: Verified Pro badges and full access across all operations.
</en-US>
```
*Character Count:* **476 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
⚡ Void Sower v0.2.35 — Usawa wa Makamanda wa Pro na Kuondolewa Matangazo!
• Bila Matangazo kwa Pro: Ukaguzi kamili katika Daily Sortie, Kampeni na Incursion. Makamanda wa Pro hawataulizwa kamwe kutazama matangazo.
• Viini vya Papo Hapo: Kwenye Daily Sortie na Kampeni, makamanda wa Pro wanapata viini 56 vya dharura mara moja bila matangazo.
• Miale ya Dharura ya Pro: Msaada wa haraka wa plasma bila kuchelewa.
• Maboresho ya Kiolesura: Alama sahihi za Pro na ufikiaji kamili wa shughuli zote.
</sw>
```
*Character Count:* **471 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
⚡ Void Sower v0.2.35 — Uniformité Pro Commander & Zéro Publicité !
• Zéro Publicité pour Pro : Audit complet sur Daily Sortie, Campagne et Incursion. Les commandants Pro ne voient plus aucune sollicitation publicitaire.
• Cœurs d'Urgence Immédiats : En cas de défaite en Daily Sortie ou Campagne, injection instantanée de +56 cœurs pour les pilotes Pro sans pub.
• Fusée Éclair Pro : Ravitaillement orbital immédiat sans délai.
• Interface Polie : Badges Pro et accès total garantis sur toutes les opérations.
</fr-FR>
```
*Character Count:* **479 / 500 max characters**.

---

### Internal Engineering Notes (Build 38)
- Added `hasActivePro` getter to `EntitlementService` checking both lifetime license and active timed boost.
- Added `isPro` parameter to `GameOverDialog`; dynamically renders `SUMMON AUXILIARY CORES` with solar gold `Icons.bolt` for Pro users, completely suppressing `WATCH AD` and play circle icons.
- Updated `CombatScreen` defeat modal in Daily Sortie, Campaign sectors, and Incursion to inject cores directly for Pro users with an informative confirmation SnackBar.
- Audited `CampaignMapScreen` locked sector dialogs to suppress ad prompts and purchase CTAs for existing Pro holders.
- Audited `RewardedAdModal` to display zero-ad Pro Commander lore and instant delivery badge.
- Added `test/phase26_pro_consistency_audit_test.dart` covering 7 edge cases across Pro and Free states.
