ESX = nil

pawnshopcoords = vector3(174.523, -1318.967, 28.347)
sellerpedcoords = vector3(172.700, -1318.041, 28.347)
coords = vector3(0.0, 0.0, 0.0)

items = {
    {label = 'Kajdanki', value = 'handcuffs', baseprice = 5000},
    {label = 'Krótkofalówka', value = 'radiocrime', baseprice = 6250},
    {label = 'Zapalniczka', value = 'zapalniczka', baseprice = 25},
    --{label = 'Zestaw Naprawczy', value = 'fixkit', baseprice = 1500},
    {label = 'Knebel', value = 'gag', baseprice = 2500},
    {label = 'Lornetka', value = 'lornetka', baseprice = 5000},
    {label = 'Telefon', value = 'phone', baseprice = 500},
    {label = 'Wiertło', value = 'drill', baseprice = 17500},
   -- {label = 'Wytrych', value = 'wytrych', baseprice = 2500},
}

prices = {}

blockbargaining = {}

local sellerped = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
    end

    PlayerData = ESX.GetPlayerData()

    generateprices()
    initped()
end)

Citizen.CreateThread(function()
    pawnshopblip = AddBlipForCoord(pawnshopcoords)

    SetBlipSprite (pawnshopblip, 77)
    SetBlipDisplay(pawnshopblip, 4)
    SetBlipScale  (pawnshopblip, 0.7)
    SetBlipColour(pawnshopblip, 46)
    SetBlipAsShortRange(pawnshopblip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName('Lombard')
    EndTextCommandSetBlipName(pawnshopblip)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(250)
        coords = GetEntityCoords(PlayerPedId())
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        sleep = true
        local dist = GetDistanceBetweenCoords(pawnshopcoords, coords, true)
        if dist <= 20.0 then
            sleep = false
            DrawMarker(1, pawnshopcoords, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 0.8, 0, 0, 255, 100, 0, 0, 0, 1)
            if dist <= 1.25 then
                inmarker = true
                ESX.ShowHelpNotification('Naciśnij ~INPUT_CONTEXT~, aby przejrzeć ofertę ~y~lombardu')
                if IsControlJustPressed(0, 38) then
                    pawnshopmenu()
                end
            else
                if inmarker then
                    inmarker = false
                    ESX.UI.Menu.CloseAll()
                end
            end
        end
        if sleep then
            Citizen.Wait(1000)
        end
    end
end)

pawnshopmenu = function()
    PlayAmbientSpeech1(sellerped, 'Generic_Hi', 'Speech_Params_Force')
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pawnshop', {
        title    = 'Lombard',
        align    = 'center',
        elements = prices
    }, function(data, menu)
        ESX.TriggerServerCallback('richrp_lombard:getplayeritemcount', function(result)
            if result > 0 then
                menu.close()
                local choose = {}
                if not blockbargaining[data.current.value] then
                    table.insert(choose, {label = 'Targuj się', value = 'changeprice'})
                end
                table.insert(choose, {label = 'Sprzedaj', value = 'sell'})
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pawnshop_choose', {
                    title    = 'Co chcesz zrobić?',
                    align    = 'center',
                    elements = choose
                }, function(data2, menu2)
                    menu2.close()
                    if data2.current.value == 'changeprice' then
                        changeprice(data.current.label, data.current.value, data.current.price, true)
                    else
                        openquantitymenu(data.current.value, data.current.price)
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            else
                ESX.ShowNotification('~r~Nie posiadasz tego przedmiotu')
            end
        end, data.current.value)
    end, function(data, menu)
        menu.close()
    end)
end

generateprices = function()
    for k,v in pairs(items) do
        chance = math.random(10,20)
        chancenumber = tonumber('1.'..chance)
        finalprice = math.floor(v.baseprice*chancenumber)
        newlabel = v.label..' <font color=lightgreen>'..finalprice..'$</font>'
        table.insert(prices, {label = newlabel, value = v.value, price = finalprice})
    end
    table.sort(prices, function(a, b)
        return a.price > b.price
    end)
end

changeprice = function(label, item, price, canbargaining)
    local elements = {}
    if canbargaining then
        table.insert(elements, {label = 'Oferta <font color=lightgreen>'..price..'$</font>', value = 'atmprice'})
        table.insert(elements, {label = 'Targuj cenę', value = 'changeprice'})
    else
        table.insert(elements, {label = 'Ostateczna oferta <font color=lightgreen>'..price..'$</font>', value = 'atmprice'})
        table.insert(elements, {label = 'Sprzedaj', value = 'sell'})
    end
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'bargaining', {
        title    = 'Targowanie',
        align    = 'center',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'changeprice' then
            menu.close()
            local chance = math.random(0, 100)
            if chance >= 50 then
                local multiplierchange = math.random(2,5)
                local multiplierchangenumber = tonumber('1.0'..multiplierchange)
                local finalmultiplierprice = math.floor(price*multiplierchangenumber)
                changeprice(label, item, finalmultiplierprice, true)
            else
                blockbargaining[item] = true
                ESX.ShowNotification('~r~Pracownik lombardu: nie ma chuja, drożej nie kupie!')
                PlayAmbientSpeech1(sellerped, 'Generic_Curse_High', 'Speech_Params_Force_Shouted_Critical')
                ESX.PlayAnimOnPed(sellerped, 'anim@heists@ornate_bank@chat_manager', 'fail', 8.0, -1, 0)
                changeprice(label, item, price, false)
                updateprice(label, item, price)
            end
        elseif data.current.value == 'sell' then
            menu.close()
            openquantitymenu(item, price)
            blockbargaining[item] = true
            updateprice(label, item, price)
        end
    end, function(data, menu)
        menu.close()
    end)
end

openquantitymenu = function(item, price)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'pawnshop_quantity', {
        title = 'Ilość'
    }, function(data, menu)
        local quantity = tonumber(data.value)
        ESX.TriggerServerCallback('richrp_lombard:getplayeritemcount', function(result)
            if result > 0 then
                if quantity <= result then
                    menu.close()
                    TriggerServerEvent('richrp_lombard:requestsellitem', item, price, quantity, PlayerData.token)
                    PlayAmbientSpeech1(sellerped, 'Generic_Thanks', 'Speech_Params_Force_Shouted_Critical')
                else
                    ESX.ShowNotification('~r~Posiadasz tylko '..result..' tego przedmiotu')
                end
            end
        end, item)
    end, function(data,menu)
        menu.close()
    end)
end

updateprice = function(label, item, price)
    split_string = Split(label, " ")
    cuttedlabel = split_string[1]
    for k,v in pairs(prices) do
        if v.value == item then
            prices[k].price = price
            prices[k].label = cuttedlabel..' <font color=lightgreen>'..price..'$</font>'
            break
        end
    end
end

function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

initped = function()
    RequestModel(`g_m_m_korboss_01`)
	while not HasModelLoaded(`g_m_m_korboss_01`) do
	  Wait(100)
	end

    sellerped = CreatePed(5, `g_m_m_korboss_01`, sellerpedcoords, 236.775, false, true)
    FreezeEntityPosition(sellerped, true)
	SetEntityInvincible(sellerped, true)
	SetBlockingOfNonTemporaryEvents(sellerped, true)
end