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

# Google Play Console Release Notes — v0.2.4 (Build 6)

## Release Track: Internal Testing / Closed Testing (Alpha / Beta)

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🛡️ Void Sower v0.2.4 — Billing Security & Transaction Hardening Update!
• Fixed an issue where dismissing or cancelling the Google Play purchase dialog could prematurely grant Pro Commander features.
• Hardened In-App Purchase lifecycle to strictly await verified Play Store transaction completion before granting entitlements.
• Removed offline fallback bypasses in store checkout and purchase restoration.
• Enhanced UI feedback for cancelled transactions and store connection issues.
</en-US>
```
*Character Count:* **478 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🛡️ Void Sower v0.2.4 — Usalama wa Malipo na Uboreshaji wa Mfumo!
• Imerekebisha hitilafu ambapo kufuta kidirisha cha ununuzi cha Google Play kulitoa ufikiaji wa Pro kabla ya wakati.
• Uthibitishaji wa ununuzi umeimarishwa kusubiri ukamilishaji rasmi kutoka Google Play kabla ya kutoa ruhusa.
• Imeondoa njia za mkato wakati mtandao haupo kwenye ununuzi na urejeshaji wa leseni.
• Ujumbe wazi umeongezwa ununuzi unapofutwa au mtandao unapokatika.
</sw>
```
*Character Count:* **470 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🛡️ Void Sower v0.2.4 — Sécurisation des Paiements et Correction Transactionnelle !
• Correction d'un bug où l'annulation de la boîte de dialogue Google Play accordait prématurément le statut Pro.
• Le cycle d'achat attend désormais la confirmation validée du Play Store avant d'accorder les droits.
• Suppression des contournements hors ligne lors de l'achat et de la restauration.
• Retours visuels améliorés en cas d'annulation ou d'erreur de connexion au store.
</fr-FR>
```
*Character Count:* **487 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🛡️ Void Sower v0.2.4 — ¡Seguridad de Facturación y Corrección de Transacciones!
• Se corrigió un error por el cual cancelar el diálogo de compra de Google Play desbloqueaba funciones Pro antes de tiempo.
• El ciclo de compras ahora espera la confirmación oficial de Google Play antes de otorgar beneficios.
• Eliminados los atajos sin conexión en el proceso de compra y restauración.
• Mensajes claros mejorados para transacciones canceladas o errores de tienda.
</es-ES>
```
*Character Count:* **488 / 500 max characters**.

---

## ⚡ Technical Release Highlights

1. **Strict Asynchronous Transaction Awaiting (`IapService`):**
   - Replaced immediate billing flow launch returns with an asynchronous `Completer<PurchaseOutcome>` lifecycle that waits for verified Google Play `purchaseStream` events.
   - Handled `PurchaseStatus.canceled` explicitly: cancels the flow without granting Pro entitlements and displays a clean "TRANSMISSION CANCELLED" alert.
   - Handled `PurchaseStatus.error` explicitly: displays user-friendly error banners without modifying persistence state.
   - Removed test-only offline auto-grant fallbacks in `purchaseProLifetime()` and `restorePurchases()`.
2. **Entitlement Protection (`EntitlementService`):**
   - Delegated transaction confirmation strictly to verified store events, eliminating premature calls to `PersistenceService.instance.setProUnlocked(true)`.
   - Exposed `notifyEntitlementChanged()` for reactive UI synchronisation upon store receipt verification.
3. **Modal UI Hardening (`ProUpgradeModal`):**
   - Added distinct branches for `isSuccess`, `isCanceled`, and `isError`.
   - Populated explicit 2-second SnackBar durations and ensured modal dismiss occurs only on confirmed purchase.
4. **Comprehensive Test Coverage (`phase16_iap_transaction_test.dart`):**
   - Full mock harness validating cancellation, store unavailability, missing catalog metadata, network errors, and verified purchase flows with 100% pass rate.

---

## 🚀 Play Console Upload Checklist

1. **Artifact:** `build/app/outputs/bundle/release/void-sower-v0.2.4.aab` (or downloaded from GitHub Actions Release).
2. **Native Debug Symbols:** `void-sower-symbols-v0.2.4.zip`.
3. **Version Code:** `6` (`0.2.4+6`).
4. **Signing:** Upload keystore configured via `android/key.properties` (or CI GitHub repository secret `ANDROID_KEYSTORE_BASE64`).
5. **Release Track:** **Internal testing** / **Closed testing (Alpha / Beta)**.
6. **Target Audience:** All enrolled test pilots.
