-- EasyClickCasting : clic, molette et touches pour lancer des sorts
-- depuis les cadres de groupe Blizzard. Toutes classes.
-- Réglages en jeu : /ecc  (ou /easyclickcasting)
-- Les sorts sont enregistrés par ID ; le jeu lance le rang le plus élevé connu.

local ADDON = ...
local NOM = "EasyClickCasting"

---------------------------------------------------------------------------
-- Données de base
---------------------------------------------------------------------------

-- Modificateurs (préfixe d'attribut sécurisé, libellé)
local MODS = {
    { "",          "Aucun"    },
    { "ctrl-",     "Ctrl"     },
    { "alt-",      "Alt"      },
    { "shift-",    "Maj"      },
    { "alt-ctrl-", "Ctrl+Alt" },
}

-- Actions : { identifiant, libellé, touche = nom de touche WoW (actions au survol) }
local SLOTS_SOURIS = {
    { "1",  "Clic gauche"  },
    { "2",  "Clic droit"   },
    { "3",  "Clic molette" },
    { "WU", "Molette haut", touche = "MOUSEWHEELUP"   },
    { "WD", "Molette bas",  touche = "MOUSEWHEELDOWN" },
}

local SLOTS_CHIFFRES = {}
for n = 1, 6 do
    SLOTS_CHIFFRES[#SLOTS_CHIFFRES + 1] = { "K" .. n, "Touche " .. n, touche = tostring(n) }
end

local SLOTS_LETTRES = {}
for _, l in ipairs({ "A", "E", "R", "T", "F", "G", "H", "W", "X", "C", "V", "B" }) do
    SLOTS_LETTRES[#SLOTS_LETTRES + 1] = { "K" .. l, "Touche " .. l, touche = l }
end

local PAGES = {
    { titre = "Souris",      slots = SLOTS_SOURIS   },
    { titre = "Touches 1-6", slots = SLOTS_CHIFFRES },
    { titre = "Lettres",     slots = SLOTS_LETTRES  },
}

-- Toutes les actions déclenchées au survol (molette + clavier)
local SURVOL = {}
for _, page in ipairs(PAGES) do
    for _, s in ipairs(page.slots) do
        if s.touche then SURVOL[#SURVOL + 1] = s end
    end
end

-- Config de départ par classe (les autres classes démarrent vides)
local DEFAUTS = {
    PRIEST = {
        ["|1"]       = 2050,  -- Clic gauche       : Soins inférieurs
        ["|2"]       = 17,    -- Clic droit        : Mot de pouvoir : Bouclier
        ["shift-|1"] = 2054,  -- Maj + clic gauche : Soins
        ["alt-|1"]   = 1243,  -- Alt + clic gauche : Mot de pouvoir : Robustesse
        ["|WU"]      = 139,   -- Molette haut      : Rénovation
        ["ctrl-|1"]  = "CIBLER", -- Ctrl + clic gauche : cibler
        ["ctrl-|2"]  = "MENU",   -- Ctrl + clic droit  : menu
    },
}

-- Actions spéciales proposées en haut de la liste des sorts
local SPECIAUX = {
    CIBLER = { nom = "Cibler le joueur", icone = "Interface\\Icons\\Ability_Hunter_SniperShot" },
    MENU   = { nom = "Menu du joueur",   icone = "Interface\\Icons\\INV_Misc_Note_01", clicSeulement = true },
}
local ORDRE_SPECIAUX = { "CIBLER", "MENU" }

local DB

local function Message(txt)
    print("|cff66ccff" .. NOM .. "|r : " .. txt)
end

local function NomDuSort(id)
    if type(id) ~= "number" then return nil end
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
end

local function IconeDuSort(id)
    if type(id) ~= "number" then return nil end
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    if GetSpellTexture then return GetSpellTexture(id) end
    if GetSpellInfo then return (select(3, GetSpellInfo(id))) end
end

-- Nom et icône d'une valeur réglée (ID de sort ou action spéciale)
local function NomAction(v)
    if SPECIAUX[v] then return SPECIAUX[v].nom end
    return NomDuSort(v)
end

local function IconeAction(v)
    if SPECIAUX[v] then return SPECIAUX[v].icone end
    return IconeDuSort(v)
end

local function LibelleCombo(mod, slot)
    if mod[1] == "" then return slot[2] end
    return mod[2] .. " + " .. slot[2]
end

local function DefautsDeClasse()
    local _, classe = UnitClass("player")
    return DEFAUTS[classe] or {}
end

local function InitDB()
    if type(EasyClickCastingDB) ~= "table" then EasyClickCastingDB = {} end
    if type(EasyClickCastingDB.binds) ~= "table" then
        EasyClickCastingDB.binds = {}
        for k, v in pairs(DefautsDeClasse()) do EasyClickCastingDB.binds[k] = v end
    end
    -- Cadre de groupe en solo : activé par défaut
    if type(EasyClickCastingDB.solo) ~= "table" then
        EasyClickCastingDB.solo = { actif = true }
    end
    DB = EasyClickCastingDB
end

---------------------------------------------------------------------------
-- Partie sécurisée : molette et touches au survol des cadres
---------------------------------------------------------------------------

local header = CreateFrame("Frame", "ECCHeader", UIParent, "SecureHandlerBaseTemplate")

-- Un bouton invisible par combinaison (modificateur x action au survol)
local boutonsSurvol = {}
local NB_SURVOL = #MODS * #SURVOL
for i = 1, NB_SURVOL do
    local b = CreateFrame("Button", "ECCSurvol" .. i, UIParent, "SecureActionButtonTemplate")
    b:SetAttribute("type", "spell")
    b:SetAttribute("*type", "spell")
    b:RegisterForClicks("AnyUp", "AnyDown")
    header:SetFrameRef("m" .. i, b)
    boutonsSurvol[i] = b
end
header:SetAttribute("nbm", NB_SURVOL)

-- Au survol : les touches réglées lancent le sort sur ce joueur
local SNIPPET_ENTREE = [[
    local unit = self:GetAttribute("unit")
    if not unit then return end
    owner:ClearBindings()
    local n = owner:GetAttribute("nbm") or 0
    for i = 1, n do
        local key = owner:GetAttribute("mkey" .. i)
        if key then
            local b = owner:GetFrameRef("m" .. i)
            b:SetAttribute("unit", unit)
            b:SetAttribute("*unit", unit)
            owner:SetBindingClick(true, key, "ECCSurvol" .. i)
        end
    end
]]
-- En quittant le cadre : les touches retrouvent leur rôle habituel
local SNIPPET_SORTIE = [[ owner:ClearBindings() ]]

local function AppliquerSurvol()
    local i = 0
    for _, m in ipairs(MODS) do
        for _, s in ipairs(SURVOL) do
            i = i + 1
            local b = boutonsSurvol[i]
            local v = DB.binds[m[1] .. "|" .. s[1]]
            local nom = NomDuSort(v)
            local typ = (v == "CIBLER") and "target" or "spell"
            b:SetAttribute("type", typ)
            b:SetAttribute("*type", typ)
            b:SetAttribute("spell", nom)
            b:SetAttribute("*spell", nom)
            if nom or v == "CIBLER" then
                -- "alt-ctrl-" + "A" -> "ALT-CTRL-A"
                header:SetAttribute("mkey" .. i, m[1]:upper() .. s.touche)
            else
                header:SetAttribute("mkey" .. i, nil)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Partie sécurisée : clics sur les cadres
---------------------------------------------------------------------------

local cadres, origine, enrobes, enAttente = {}, {}, {}, {}
local aRefaire = false

local function AppliquerCadre(frame)
    if not DB then return end
    if InCombatLockdown() then
        enAttente[frame] = true
        return
    end

    -- Comportement d'origine du cadre, mémorisé une fois
    local o = origine[frame]
    if not o then
        o = {
            frame:GetAttribute("type1"),
            frame:GetAttribute("type2"),
            menu = frame:GetAttribute("*type2") or frame:GetAttribute("type2") or "togglemenu",
        }
        origine[frame] = o
    end

    -- Ajoute le clic molette aux clics gérés par le cadre
    frame:RegisterForClicks("LeftButtonDown", "RightButtonUp", "MiddleButtonUp")

    for _, m in ipairs(MODS) do
        for b = 1, 3 do
            local v = DB.binds[m[1] .. "|" .. b]
            local nom = NomDuSort(v)
            if v == "CIBLER" then
                frame:SetAttribute(m[1] .. "type" .. b, "target")
                frame:SetAttribute(m[1] .. "spell" .. b, nil)
            elseif v == "MENU" then
                frame:SetAttribute(m[1] .. "type" .. b, o.menu)
                frame:SetAttribute(m[1] .. "spell" .. b, nil)
            elseif nom then
                frame:SetAttribute(m[1] .. "type" .. b, "spell")
                frame:SetAttribute(m[1] .. "spell" .. b, nom)
            else
                if m[1] == "" and b <= 2 then
                    frame:SetAttribute("type" .. b, o[b])
                else
                    frame:SetAttribute(m[1] .. "type" .. b, nil)
                end
                frame:SetAttribute(m[1] .. "spell" .. b, nil)
            end
        end
    end

    if not enrobes[frame] then
        header:WrapScript(frame, "OnEnter", SNIPPET_ENTREE)
        header:WrapScript(frame, "OnLeave", SNIPPET_SORTIE)
        header:WrapScript(frame, "OnHide", SNIPPET_SORTIE)
        enrobes[frame] = true
    end
end

local function Ajouter(frame)
    if type(frame) ~= "table" or not frame.SetAttribute or not frame.RegisterForClicks then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    if cadres[frame] then return end
    cadres[frame] = true
    AppliquerCadre(frame)
end

-- Le portrait du joueur (PlayerFrame) est volontairement ignoré :
-- il garde son comportement normal. Seuls les cadres de groupe/raid sont gérés.
local function Scanner()
    for i = 1, 4 do Ajouter(_G["PartyMemberFrame" .. i]) end
    for i = 1, 5 do Ajouter(_G["CompactPartyFrameMember" .. i]) end
    for i = 1, 40 do Ajouter(_G["CompactRaidFrame" .. i]) end
    for g = 1, 8 do
        for m = 1, 5 do
            Ajouter(_G["CompactRaidGroup" .. g .. "Member" .. m])
        end
    end
end

local AppliquerSolo

local function AppliquerTout()
    if not DB then return false end
    if InCombatLockdown() then
        aRefaire = true
        return false
    end
    ClearOverrideBindings(header)
    AppliquerSurvol()
    for f in pairs(cadres) do AppliquerCadre(f) end
    AppliquerSolo()
    return true
end

-- Les cadres créés ou réinitialisés plus tard (nouveau membre, passage en raid)
if CompactUnitFrame_SetUpFrame then
    hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame)
        if frame.IsForbidden and frame:IsForbidden() then return end
        local n = frame.GetName and frame:GetName()
        if n and (n:find("^CompactParty") or n:find("^CompactRaid") or n:find("^ECCSolo")) then
            cadres[frame] = true
            AppliquerCadre(frame)
        end
    end)
end

---------------------------------------------------------------------------
-- Cadre de groupe en solo : le joueur dans un cadre style raid quand il
-- n'est pas groupé, avec tous les raccourcis. Les cadres Blizzard ne sont
-- pas modifiés ; ce cadre disparaît dès qu'on rejoint un groupe.
---------------------------------------------------------------------------

local Solo, SoloPoignee

-- Cadre maison : on n'utilise pas le modèle CompactUnitFrame de Blizzard,
-- car le piloter depuis un addon « contamine » son code, qui ne peut plus
-- lire les valeurs secrètes du client (portée, etc.) et lève des erreurs.
local function CreerUnite(parent)
    local u = CreateFrame("Button", "ECCSoloUnit", parent, "SecureUnitButtonTemplate")
    u:SetAttribute("unit", "player")
    u:SetAttribute("*type1", "target")
    u:SetAttribute("*type2", "togglemenu")

    local fond = u:CreateTexture(nil, "BACKGROUND")
    fond:SetAllPoints()
    fond:SetColorTexture(0.1, 0.1, 0.1, 0.85)

    local barre = CreateFrame("StatusBar", nil, u)
    barre:SetPoint("TOPLEFT", 1, -1)
    barre:SetPoint("BOTTOMRIGHT", -1, 1)
    barre:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    local _, classe = UnitClass("player")
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classe]
    if c then barre:SetStatusBarColor(c.r, c.g, c.b) else barre:SetStatusBarColor(0, 0.8, 0) end

    local nom = barre:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nom:SetPoint("CENTER")
    nom:SetText(UnitName("player"))

    -- Les points de vie peuvent être des valeurs secrètes : on les passe
    -- directement à la barre, sans jamais les tester ni les comparer.
    local function MAJ()
        barre:SetMinMaxValues(0, UnitHealthMax("player"))
        barre:SetValue(UnitHealth("player"))
    end
    u:RegisterEvent("PLAYER_ENTERING_WORLD")
    u:RegisterEvent("UNIT_HEALTH")
    u:RegisterEvent("UNIT_MAXHEALTH")
    pcall(u.RegisterEvent, u, "UNIT_HEALTH_FREQUENT")
    u:SetScript("OnEvent", function(_, _, unit)
        if unit == nil or unit == "player" then pcall(MAJ) end
    end)
    pcall(MAJ)
    return u
end

local function CreerSolo()
    if Solo or InCombatLockdown() then return end
    Solo = CreateFrame("Frame", "ECCSolo", UIParent, "SecureHandlerStateTemplate")
    Solo:SetSize(72, 36)
    Solo:SetMovable(true)
    Solo:SetClampedToScreen(true)
    local pos = DB.solo.pos
    if pos then
        Solo:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        Solo:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 30, -220)
    end

    local u = CreerUnite(Solo)
    u:SetAllPoints(Solo)
    Ajouter(u)

    -- Poignée pour déplacer le cadre (visible seulement en mode déplacement)
    local p = CreateFrame("Frame", nil, Solo)
    p:SetAllPoints(Solo)
    p:SetFrameLevel(u:GetFrameLevel() + 10)
    p:EnableMouse(true)
    p:RegisterForDrag("LeftButton")
    local t = p:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    t:SetColorTexture(0.2, 0.6, 1, 0.45)
    local txt = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("CENTER")
    txt:SetText("Glisser")
    p:SetScript("OnDragStart", function()
        if not InCombatLockdown() then Solo:StartMoving() end
    end)
    p:SetScript("OnDragStop", function()
        Solo:StopMovingOrSizing()
        Solo:SetUserPlaced(false)
        local pt, _, rp, x, y = Solo:GetPoint()
        DB.solo.pos = { pt, rp, x, y }
    end)
    p:Hide()
    SoloPoignee = p
end

function AppliquerSolo()
    if not DB then return end
    if InCombatLockdown() then
        aRefaire = true
        return
    end
    if DB.solo.actif then
        CreerSolo()
        if Solo then RegisterStateDriver(Solo, "visibility", "[group] hide; show") end
    elseif Solo then
        UnregisterStateDriver(Solo, "visibility")
        Solo:Hide()
        if SoloPoignee then SoloPoignee:Hide() end
    end
end

local function BasculerDeplacement()
    if not (DB.solo.actif and Solo) then
        Message("active d'abord « Mon cadre en solo ».")
        return
    end
    if not Solo:IsShown() then
        Message("le cadre solo n'est visible que hors groupe.")
        return
    end
    SoloPoignee:SetShown(not SoloPoignee:IsShown())
end

---------------------------------------------------------------------------
-- Liste des sorts du grimoire (toutes classes)
---------------------------------------------------------------------------

local function SortsDuGrimoire()
    local liste, vus = {}, {}
    local function ajouter(id)
        local nom = NomDuSort(id)
        if nom and not vus[nom] then
            vus[nom] = true
            liste[#liste + 1] = { id = id, nom = nom, icone = IconeDuSort(id) }
        end
    end
    pcall(function()
        if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
            local banque = Enum.SpellBookSpellBank.Player
            for t = 1, C_SpellBook.GetNumSpellBookSkillLines() do
                local info = C_SpellBook.GetSpellBookSkillLineInfo(t)
                if info and not info.shouldHide then
                    for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                        local item = C_SpellBook.GetSpellBookItemInfo(i, banque)
                        if item and item.itemType == Enum.SpellBookItemType.Spell
                            and not item.isPassive and not item.isOffSpec then
                            ajouter(item.spellID)
                        end
                    end
                end
            end
        elseif GetNumSpellTabs then
            local livre = BOOKTYPE_SPELL or "spell"
            for t = 1, GetNumSpellTabs() do
                local _, _, offset, nb = GetSpellTabInfo(t)
                for i = offset + 1, offset + nb do
                    local typ, id = GetSpellBookItemInfo(i, livre)
                    local passif = IsPassiveSpell and IsPassiveSpell(i, livre)
                    if typ == "SPELL" and id and not passif then ajouter(id) end
                end
            end
        end
    end)
    table.sort(liste, function(a, b) return a.nom < b.nom end)
    return liste
end

local function SortDuCurseur()
    local typ, a, b, c = GetCursorInfo()
    if typ ~= "spell" then return nil end
    if type(c) == "number" and c > 0 then return c end
    if GetSpellBookItemInfo then
        local _, id = GetSpellBookItemInfo(a, b)
        if id then return id end
    end
end

---------------------------------------------------------------------------
-- Fenêtre de réglage
---------------------------------------------------------------------------

local Fenetre, Selecteur, Defilement
local cellules, pagesUI, onglets = {}, {}, {}
local celluleActive

local LARG_CELL, HAUT_CELL = 88, 54
local COL_LIBELLE = 100
local HAUT_DEFIL = 6 * HAUT_CELL
local LARG_CONTENU = COL_LIBELLE + #MODS * LARG_CELL
local LARG_FEN = 12 + LARG_CONTENU + 34
local HAUT_FEN = 104 + HAUT_DEFIL + 48

local function CreerCadre(nom, parent, largeur, hauteur)
    local ok, f = pcall(CreateFrame, "Frame", nom, parent, "BasicFrameTemplateWithInset")
    if not ok or not f then
        f = CreateFrame("Frame", nom .. "Simple", parent)
        local fond = f:CreateTexture(nil, "BACKGROUND")
        fond:SetAllPoints()
        fond:SetColorTexture(0.05, 0.05, 0.08, 0.94)
        local fermer = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        fermer:SetPoint("TOPRIGHT", 2, 2)
    end
    f:SetSize(largeur, hauteur)
    f:EnableMouse(true)
    return f
end

local function ErreurCombat()
    UIErrorsFrame:AddMessage(NOM .. " : impossible de modifier en combat", 1, 0.2, 0.2)
end

local RafraichirFenetre

local function Assigner(cle, id)
    if InCombatLockdown() then ErreurCombat() return end
    DB.binds[cle] = id
    AppliquerTout()
    RafraichirFenetre()
end

local function FermerSelecteur()
    celluleActive = nil
    if Selecteur then Selecteur:Hide() end
    if Fenetre then RafraichirFenetre() end
end

local function CreerSelecteur()
    local s = CreerCadre("ECCSelecteur", Fenetre, 250, HAUT_FEN)
    s:SetPoint("TOPLEFT", Fenetre, "TOPRIGHT", 2, 0)
    s:SetFrameStrata("DIALOG")

    local titre = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titre:SetPoint("TOP", 0, -5)
    titre:SetText("Choisir un sort")

    s.sous = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    s.sous:SetPoint("TOPLEFT", 14, -34)

    s.vide = s:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    s.vide:SetPoint("TOPLEFT", 14, -60)
    s.vide:SetWidth(220)
    s.vide:SetJustifyH("LEFT")
    s.vide:SetText("Liste indisponible : glisse le sort depuis le grimoire sur la case.")

    local sf = CreateFrame("ScrollFrame", "ECCSelecteurScroll", s, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 12, -56)
    sf:SetPoint("BOTTOMRIGHT", -32, 12)
    local enfant = CreateFrame("Frame", nil, sf)
    enfant:SetSize(200, 1)
    sf:SetScrollChild(enfant)

    s.enfant = enfant
    s.lignes = {}
    s:SetScript("OnHide", function()
        celluleActive = nil
        if Fenetre and Fenetre:IsShown() then RafraichirFenetre() end
    end)
    Selecteur = s
end

local function OuvrirSelecteur(cellule)
    if not Selecteur then CreerSelecteur() end
    celluleActive = cellule
    local sorts = SortsDuGrimoire()
    -- Actions spéciales en tête (Menu seulement pour les clics)
    local liste = {}
    for _, cle in ipairs(ORDRE_SPECIAUX) do
        local sp = SPECIAUX[cle]
        if not (sp.clicSeulement and cellule.auSurvol) then
            liste[#liste + 1] = { id = cle, nom = "|cff66ccff" .. sp.nom .. "|r", icone = sp.icone }
        end
    end
    for _, sp in ipairs(sorts) do liste[#liste + 1] = sp end
    for i, sp in ipairs(liste) do
        local l = Selecteur.lignes[i]
        if not l then
            l = CreateFrame("Button", nil, Selecteur.enfant)
            l:SetSize(200, 22)
            l:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
            l.icone = l:CreateTexture(nil, "ARTWORK")
            l.icone:SetSize(20, 20)
            l.icone:SetPoint("LEFT")
            l.texte = l:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            l.texte:SetPoint("LEFT", l.icone, "RIGHT", 6, 0)
            l.texte:SetPoint("RIGHT")
            l.texte:SetJustifyH("LEFT")
            l.texte:SetWordWrap(false)
            l:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            l:SetScript("OnClick", function(self)
                if celluleActive then
                    local cle = celluleActive.cle
                    FermerSelecteur()
                    Assigner(cle, self.id)
                end
            end)
            Selecteur.lignes[i] = l
        end
        l.id = sp.id
        l.icone:SetTexture(sp.icone)
        l.texte:SetText(sp.nom)
        l:Show()
    end
    for i = #liste + 1, #Selecteur.lignes do Selecteur.lignes[i]:Hide() end
    Selecteur.enfant:SetHeight(math.max(1, #liste * 22))
    Selecteur.sous:SetText(cellule.libelle)
    if #sorts == 0 then Selecteur.vide:Show() else Selecteur.vide:Hide() end
    Selecteur:Show()
    RafraichirFenetre()
end

function RafraichirFenetre()
    for _, c in ipairs(cellules) do
        local id = DB.binds[c.cle]
        local nom = NomAction(id)
        if nom then
            c.icone:SetTexture(IconeAction(id))
            c.icone:Show()
            c.plus:Hide()
            c.texte:SetText(nom)
        else
            c.icone:Hide()
            c.plus:Show()
            c.texte:SetText("")
        end
        if c == celluleActive then c.sel:Show() else c.sel:Hide() end
    end
end

local function CreerCellule(page, col, ligne, mod, slot)
    local c = CreateFrame("Button", nil, page)
    c:SetSize(36, 36)
    c:SetPoint("TOP", page, "TOPLEFT", COL_LIBELLE + (col - 0.5) * LARG_CELL, -(ligne - 1) * HAUT_CELL - 4)
    c.cle = mod[1] .. "|" .. slot[1]
    c.libelle = LibelleCombo(mod, slot)
    c.auSurvol = slot.touche ~= nil

    c.sel = c:CreateTexture(nil, "BACKGROUND", nil, -1)
    c.sel:SetPoint("TOPLEFT", -3, 3)
    c.sel:SetPoint("BOTTOMRIGHT", 3, -3)
    c.sel:SetColorTexture(1, 0.82, 0, 0.9)
    c.sel:Hide()

    local fond = c:CreateTexture(nil, "BACKGROUND")
    fond:SetAllPoints()
    fond:SetColorTexture(0, 0, 0, 0.6)

    c.icone = c:CreateTexture(nil, "ARTWORK")
    c.icone:SetPoint("TOPLEFT", 2, -2)
    c.icone:SetPoint("BOTTOMRIGHT", -2, 2)

    c.plus = c:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    c.plus:SetPoint("CENTER")
    c.plus:SetText("+")

    c.texte = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.texte:SetPoint("TOP", c, "BOTTOM", 0, -2)
    c.texte:SetWidth(LARG_CELL - 6)
    c.texte:SetWordWrap(false)

    c:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    c:SetScript("OnReceiveDrag", function(self)
        local id = SortDuCurseur()
        if id then
            ClearCursor()
            Assigner(self.cle, id)
        end
    end)
    c:SetScript("OnClick", function(self, bouton)
        if bouton == "RightButton" then
            Assigner(self.cle, nil)
            return
        end
        local id = SortDuCurseur()
        if id then
            ClearCursor()
            Assigner(self.cle, id)
        elseif celluleActive == self then
            FermerSelecteur()
        else
            OuvrirSelecteur(self)
        end
    end)
    c:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.libelle)
        local nom = NomAction(DB.binds[self.cle])
        if nom then
            GameTooltip:AddLine(nom, 1, 1, 1)
        else
            GameTooltip:AddLine("Vide", 0.6, 0.6, 0.6)
        end
        if self.auSurvol then
            GameTooltip:AddLine("Active seulement quand la souris survole un cadre de groupe.", 0.8, 0.8, 0.8, true)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Clic : choisir un sort", 0.5, 0.8, 1)
        GameTooltip:AddLine("Ou glisser un sort du grimoire ici", 0.5, 0.8, 1)
        GameTooltip:AddLine("Clic droit : effacer", 0.5, 0.8, 1)
        GameTooltip:Show()
    end)
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)

    cellules[#cellules + 1] = c
end

local function CreerPage(index)
    local def = PAGES[index]
    local page = CreateFrame("Frame", nil, Defilement)
    page:SetSize(LARG_CONTENU, #def.slots * HAUT_CELL + 8)
    for ligne, slot in ipairs(def.slots) do
        local t = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -(ligne - 1) * HAUT_CELL - 14)
        t:SetText(slot[2])
        for col, mod in ipairs(MODS) do
            CreerCellule(page, col, ligne, mod, slot)
        end
    end
    page:Hide()
    pagesUI[index] = page
end

local function MontrerPage(index)
    FermerSelecteur()
    for i, page in ipairs(pagesUI) do
        if i == index then page:Show() else page:Hide() end
    end
    Defilement:SetScrollChild(pagesUI[index])
    Defilement:SetVerticalScroll(0)
    for i, o in ipairs(onglets) do
        if i == index then o:LockHighlight() else o:UnlockHighlight() end
    end
end

local function CreerFenetre()
    local f = CreerCadre("ECCFenetre", UIParent, LARG_FEN, HAUT_FEN)
    Fenetre = f
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnHide", function()
        if Selecteur then Selecteur:Hide() end
        if SoloPoignee then SoloPoignee:Hide() end
    end)
    table.insert(UISpecialFrames, f:GetName())

    local titre = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titre:SetPoint("TOP", 0, -5)
    titre:SetText(NOM)

    local aide = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    aide:SetPoint("TOPLEFT", 16, -32)
    aide:SetText("Clique une case pour choisir un sort, ou glisse-le depuis le grimoire. Clic droit : effacer.")

    for i, def in ipairs(PAGES) do
        local o = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        o:SetSize(112, 22)
        o:SetPoint("TOPLEFT", 14 + (i - 1) * 118, -50)
        o:SetText(def.titre)
        o:SetScript("OnClick", function() MontrerPage(i) end)
        onglets[i] = o
    end

    for col, mod in ipairs(MODS) do
        local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOP", f, "TOPLEFT", 12 + COL_LIBELLE + (col - 0.5) * LARG_CELL, -84)
        t:SetText(mod[2])
    end

    Defilement = CreateFrame("ScrollFrame", "ECCDefilement", f, "UIPanelScrollFrameTemplate")
    Defilement:SetPoint("TOPLEFT", 12, -104)
    Defilement:SetSize(LARG_CONTENU, HAUT_DEFIL)

    for i = 1, #PAGES do CreerPage(i) end

    local note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("BOTTOMRIGHT", -16, 18)
    note:SetText("Cibler / Menu : en haut de la liste")

    local caseSolo = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    caseSolo:SetSize(24, 24)
    caseSolo:SetPoint("BOTTOMLEFT", 150, 11)
    local libSolo = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    libSolo:SetPoint("LEFT", caseSolo, "RIGHT", 2, 0)
    libSolo:SetText("Mon cadre en solo")
    caseSolo:SetScript("OnClick", function(self)
        if InCombatLockdown() then
            ErreurCombat()
            self:SetChecked(DB.solo.actif)
            return
        end
        DB.solo.actif = self:GetChecked() and true or false
        AppliquerSolo()
    end)
    caseSolo:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Mon cadre en solo")
        GameTooltip:AddLine("Affiche ton personnage dans un cadre style raid quand tu n'es pas groupé, avec tous tes raccourcis. Il disparaît dès que tu rejoins un groupe.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    caseSolo:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.caseSolo = caseSolo

    local deplacer = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    deplacer:SetSize(90, 22)
    deplacer:SetPoint("BOTTOMLEFT", 290, 12)
    deplacer:SetText("Déplacer")
    deplacer:SetScript("OnClick", BasculerDeplacement)

    local defaut = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    defaut:SetSize(130, 22)
    defaut:SetPoint("BOTTOMLEFT", 14, 12)
    defaut:SetText("Config par défaut")
    defaut:SetScript("OnClick", function()
        if InCombatLockdown() then ErreurCombat() return end
        wipe(DB.binds)
        for k, v in pairs(DefautsDeClasse()) do DB.binds[k] = v end
        FermerSelecteur()
        AppliquerTout()
        RafraichirFenetre()
    end)

    MontrerPage(1)
    f:Hide()
end

local function BasculerFenetre()
    if not DB then return end
    if not Fenetre then CreerFenetre() end
    if Fenetre:IsShown() then
        Fenetre:Hide()
    else
        RafraichirFenetre()
        Fenetre.caseSolo:SetChecked(DB.solo.actif)
        Fenetre:Show()
    end
end

---------------------------------------------------------------------------
-- Événements et commandes
---------------------------------------------------------------------------

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        AppliquerTout()
        Scanner()
        Message("chargé. /ecc pour régler les sorts.")
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        for frame in pairs(enAttente) do
            enAttente[frame] = nil
            AppliquerCadre(frame)
        end
        if aRefaire then
            aRefaire = false
            AppliquerTout()
        end
    end
    if DB and not InCombatLockdown() then Scanner() end
end)

local function Commande(msg)
    msg = (msg or ""):lower()
    if not DB then return end
    if msg == "liste" then
        local n = 0
        for _ in pairs(cadres) do n = n + 1 end
        Message(n .. " cadres pris en charge.")
        for _, page in ipairs(PAGES) do
            for _, slot in ipairs(page.slots) do
                for _, mod in ipairs(MODS) do
                    local nom = NomAction(DB.binds[mod[1] .. "|" .. slot[1]])
                    if nom then Message("  " .. LibelleCombo(mod, slot) .. " = " .. nom) end
                end
            end
        end
        return
    end
    BasculerFenetre()
end

SLASH_EASYCLICKCASTING1 = "/ecc"
SLASH_EASYCLICKCASTING2 = "/easyclickcasting"
SlashCmdList["EASYCLICKCASTING"] = Commande
