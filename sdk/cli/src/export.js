
export async function exportActions(argv) {
  
}

export async function getSupporters(argv) {
  const c = argv2client(argv);
  await streamSignatures(c, argv.org, argv.campaignId, sigs => {
    const signatures = decryptSignatures(sigs, config);
    console.log(signatures);
  });
}

export async function getCsvSupporters(argv) {
  const c = argv2client(argv);
  const file = new Date().toISOString().substring(0, 10) + ".csv";
  const csvWriter = createCsvWriter({
    path: file,
    headerIdDelimiter: ".",
    header: [
      { id: "actionPageId", title: "page" },
      { id: "campaignId", title: "campaign" },
      { id: "contact.first_name", title: "firstname" },
      { id: "contact.last_name", title: "lastname" },
      { id: "contact.email", title: "email" },
      { id: "contact.postcode", title: "postcode" },
      { id: "contact.country", title: "country" },
      { id: "created", title: "date" },
      { id: "id", title: "id" },
      { id: "optIn", title: "optin" }
    ]
  });
  console.log("writing to " + file);
  await streamSignatures(c, argv.org, argv.campaignId, sigs => {
    const signatures = decryptSignatures(sigs, config);
    csvWriter.writeRecords(signatures);
  });
}


export async function deliver(argv) {
  if (argv.check) {
    testQueue(config);
  } else if (argv.service) {
    let service = require(`./service/${argv.service}`);
    if (argv.backoff) {
      service.syncAction = addBackoff(service.syncAction);
    }
    try {
      await syncQueue(service, config, argv);
    } catch (error) {
      console.error(`🙄 Problem delivering to service. I give up: ${error}`);
    }
  }
  return true;
}
