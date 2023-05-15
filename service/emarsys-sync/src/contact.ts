
import {ActionMessageV2, EventMessageV2} from '@proca/queue';

import countries from 'i18n-iso-countries';
import enCountries from 'i18n-iso-countries/langs/en.json';

// patch naming discrepancies...
enCountries.countries['NL'] = 'The Netherlands';

countries.registerLocale(enCountries);

export const getCountry = (c:string) => countries.getName(c, "en");

export const TRUE = 1;
export const FALSE = 2;
type BOOLEAN = 1 | 2 | undefined;

export const isTrue = (v : string | number) => v === 1 || (typeof v === 'string' && parseInt(v) === 1);
export const isFalse = (v : string | number) => v === 2 || (typeof v === 'string' && parseInt(v) === 2);

export const eventToContact = (msg : EventMessageV2) : Record<string, any> | null => {
  if (msg.eventType === "email_status") {
    const c = msg.supporter.contact;
    const p = msg.supporter.privacy;

    if (p.emailStatus === null) return null;

    const optIn = msg.supporter.privacy.emailStatus === 'double_opt_in';

    const record = {
      identifier: c.contactRef,
      optin: optIn ? TRUE : FALSE
    }

    return record;
  }

  return null;
};

export const actionToContact = (msg : ActionMessageV2) : Record<string,any> => {
  const c = msg.contact;
  const ap = msg.actionPage;
  let optin : BOOLEAN = undefined;

  switch (msg.privacy.emailStatus) {
      case 'double_opt_in': { optin = TRUE; break; }
      case 'spam':
      case 'unsub':
      case 'blocked':
      case 'bounce':
      {
        optin = FALSE;
      }
      default: {
        // said no on form
        if (msg.privacy.optIn === false) {
          optin = FALSE;
        }
      }
  }

  const country = c.country ? countries.getName(c.country.toUpperCase(), "en") : undefined;

  let salutation : string = undefined;

  switch (msg.action.customFields.salutation) {
      case 'm': { salutation = 'Mr.'; break }
      case 'f': { salutation = 'Ms.'; break }
      case 'other': { salutation = 'Mx.'; break }
      default: { salutation = null; break }
  }

  const record = {
    first_name: c.firstName,
    last_name: c.lastName,
    salutation,
    email: c.email,
    identifier: c.contactRef,
    phone: c.phone,
    address: c.address?.street,
    city: c.address?.locality,
    state: c.address?.region,
    zip_code: c.postcode,
    country,
    ietf_language_tag: ap.locale.replace('_', '-'), // ietf format eg en-US
    optin,
    key1: 'proca'
 //   registration_date: msg.action.createdAt.split('T')[0] // YYYY-MM-DD
  };

  if (record.first_name === 'supporter')
    record.first_name = '';

  // XXX SALUTATION
  return record;


  /*
    first_name: 1,
    last_name: 2,
    email: 3,
    address: 10,

    city: 11,
    state: 12,
    zip_code: 13,
    salutation: 46,
    country: 14,
    ietf_language_tag: 618,
    optin: 31, // Opt-in 1=true 2=false
    phone: 15,
    registration_date: 48

   *
   *   interests: 0,
    title: 9,
    preferred_email_format: 26,
    phone: 15,
    mobile: 37,
    fax: 16,
    gender: 5,
    birth_date: 4,
    education: 8,
    marital_status: 6,
    partner_first_name: 38,
    partner_birth_date: 39,
    anniversary: 40,
    children: 7,
    company_name: 18,
    company_address: 41,
    company_zip_code: 42,
    company_city: 43,
    company_state: 44,
    company_country: 45,
    company_phone: 21,
    company_fax: 22,
    url: 25,
    company_position: 17,
    company_department: 19,
    company_industry: 20,
    company_employees: 23,
    company_annual_revenue: 24,
    do_not_track_me: 616,
    do_not_track_me_in_email: 617,
    predictuserid: 619,
    '': 620,
    predict_top_categories: 621,
    predict_las_session_date: 622,
    predict_last_session_time_spent: 623,
    predict_last_session_products: 624,
    predict_last_session_categories: 625,
    predict_last_abandoned_date: 626,
    predict_last_abandoned_products: 627,
    predict_last_abandoned_categorie: 628,
    predict_last_abandoned_total_pri: 629,
    predict_last_purchase_date: 630,
    predict_last_purchase_products: 631,
    predict_last_purchase_categories: 632,
    predict_last_purchase_total_pric: 633,
    externalid: 793,
    ref: 794,
    average_visit_duration: 27,
    pageviews_per_day: 28,
    days_since_last_email_sent: 29,
    status: 32,
    source: 33,
    form: 34,
    registration_language: 35,
    newsletter: 36,
    email_valid: 47,

   *
   */

}
