import {Connection, Record as SFRecord} from 'jsforce'
import {ActionMessageV2} from '@proca/queue'

export const makeClient = async () => {
  const conn = new Connection({loginUrl: process.env.SALESFORCE_URL})

  if (!process.env.AUTH_USER || !process.env.AUTH_PASSWORD || !process.env.AUTH_TOKEN)
    throw new Error("Missing AUTH_USER/PASSWORD/TOKEN nenv variables")

  const u = `${process.env.AUTH_USER}`
  const p = `${process.env.AUTH_PASSWORD}${process.env.AUTH_TOKEN}`

  const userInfo = await conn.login(u, p);

  // console.log(userInfo)
  return {conn, userInfo}
}




const CampaignsByName : Record<string, SFRecord> = {};


export const campaignByName = async (conn : Connection, name : string, cached = false) => {
  let campaign
  // return cached
  if (cached && name in CampaignsByName)
    return CampaignsByName[name]

  const campaignTypeId = process.env.CAMPAIGN_RECORD_TYPE

  // fetch
  const r = await conn.sobject('Campaign').find({name})

  // fail hard on missing campaign
  if (r.length === 0) {
    console.log('will try to create ' + name)
    const cattr : Record<string,string> = {name, Type: 'Proca'}

    if (campaignTypeId)
      cattr['RecordTypeId'] = campaignTypeId

    const n = await conn.sobject('Campaign').create(cattr) //  'Proca online campaign'
    if (!n.success) throw Error(`Cannot create campaign ${name}: ${n.errors}`)
    campaign = await conn.sobject('Campaign').retrieve(n.id)
  } else {
    campaign = r[0]
  }

  CampaignsByName[name] = campaign;
  return campaign;
}

type MemberID = {
  ContactId? : string;
  LeadId? : string;
}


export const addCampaignContact = async (conn : Connection, CampaignId: string, memberId : MemberID, _action : ActionMessageV2) => {
  // const _addedDate = action.action.createdAt.split("T")[0]

  return new Promise((ok) => {
    // for chained call promise api does not work any more :/
    conn.sobject('CampaignMember').find(Object.assign({CampaignId}, memberId)).update({Status: 'Responded'}, (err, resp) => {
      if (err) throw err
      // console.log(`finding campaign membership  ${ContactId} -> ${CampaignId} = `, resp)
      if (resp.length !== 0) return ok(resp[0])
      // console.log(`creating campaign membership  ${ContactId} -> ${CampaignId}`)
      return conn.sobject('CampaignMember').create(Object.assign({CampaignId, Status: 'Responded'}, memberId), (err, resp) => {
        if (err) throw err
        return ok(resp)
      })
    })
  });
}

export const contactByEmail = async (conn : Connection, Email : string) => {
  // return await conn.query(`SELECT id, firstname, lastname, email, phone FROM Contact WHERE email =  '${email}'`)

  const r = await conn.sobject('Contact').find({Email})

  return r[0]
}

export const leadByEmail = async (conn : Connection, Email : string) => {
  // return await conn.query(`SELECT id, firstname, lastname, email, phone FROM Contact WHERE email =  '${email}'`)

  const IsConverted = false
  const r = await conn.sobject('Lead').find({Email, IsConverted})

  return r[0]
}

export const upsertLead = async (conn : Connection, contact : SFRecord) => {
  let r;

  try {
    r = await conn.sobject('Lead').upsert(contact, 'Email')
  } catch (er) {
    if (er.name === 'MULTIPLE_CHOICES') {
      const idPath = er.content[er.content.length-1].split('/')
      console.warn(`Duplicate records for ${contact.Email}:  ${er.content}, returning last one`)
      return idPath[idPath.length-1]
    } else if (er.name === 'CANNOT_UPDATE_CONVERTED_LEAD') {
      r = await conn.sobject('Lead').create(contact)
      // returns id: ... success: true
    } else {
      console.log(`LEAD UPSERT ERROR, unhandled er.name='${er.name}'`)
      throw er;
    }
  }

  // for success value, id can be there
  if (r && 'id' in r && r.id)
    return r.id  // I just can't.... id vs Id sometimes returned

  const e = await leadByEmail(conn, contact.Email)
  return e.Id
}

export const upsertContact = async (conn : Connection, contact : SFRecord) => {
  const r = await conn.sobject('Contact').upsert(contact, 'Email')

  if (!r.success) throw Error(`Error upserting contact: ${r.errors}`)
  if (r.id)
    return r.id  // I just can't.... id vs Id

  // On update, id is *not* returned - we have to fetch - SAD!
  const e = await contactByEmail(conn, contact.Email)
  return e.Id
}


export const foo = async (conn : Connection) => {
  return await conn.sobject('CampaignMember').select().offset(0).limit(10)
}
