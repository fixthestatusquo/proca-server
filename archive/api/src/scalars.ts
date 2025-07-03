
const serializers = {
      Json: {
            serialize: (v: any) => typeof v === 'string' ? v : JSON.stringify(v),
            deserialize: (v: string) => JSON.parse(v),
      },
};

export default serializers;


