import {
  IntrospectionInputTypeRef,
  IntrospectionInputType, IntrospectionQuery, IntrospectionInputObjectType, IntrospectionType} from 'graphql';

type FieldPath = {
  type: string,
  fieldType: string,
  path: string[]
}


export const getInputFieldPaths = (introspectionQuery : IntrospectionQuery, scalars : string[]) => {
  const wantedScalar = (n : string) => scalars.indexOf(n) > -1

  const inputTypes = introspectionQuery.__schema.types.
    filter(({kind}) => kind === 'INPUT_OBJECT').
    reduce((a:  Record<string, IntrospectionInputObjectType>,  x : IntrospectionType) => 
      { 
        a[x.name] = x as IntrospectionInputObjectType;
        return a;
      }, {})


  const fieldPaths : FieldPath[] = []


  const searchInputObject = (type : string, current : IntrospectionInputObjectType, path: string[]) => {

      for (const field of current.inputFields) {
        const fieldType = unpackType(field.type)

        if (fieldType === undefined) continue; // ENUMs, others?

        if (fieldType.kind === 'SCALAR' && wantedScalar(fieldType.name)) {
          fieldPaths.push({
            type: type, 
            fieldType: fieldType.name,
            path: path.concat([field.name])
          })
        } else if (fieldType.kind === 'INPUT_OBJECT') {
          searchInputObject(type, inputTypes[fieldType.name], path.concat([field.name]))
        }
      }
  }

  for (const type in inputTypes) {
    searchInputObject(type, inputTypes[type], [])
  }

  return fieldPaths;
}

const unpackType = (type : IntrospectionInputTypeRef) : IntrospectionInputTypeRef | undefined => {
  if (type.kind === 'SCALAR' || type.kind === 'INPUT_OBJECT') 
    return type;

  if (type.kind === 'LIST' || type.kind === 'NON_NULL')
    return unpackType(type.ofType)

}
