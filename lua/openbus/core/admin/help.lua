local function ToStringMetaMethod()
  return {
    type = "method",
    title = "Returns Textual Representation",
    results = {
      {
        type = "string",
        name = "string",
        title = "Textual Representation",
      }
    },
  }
end
return {
  title = "OpenBus Admin Console",
  description = [[
    <code>busadmin</code> is a console for the Lua language that provides functions that execute administation operations on a OpenBus instance.
  ]],
  fields = {
    {
      title = "Configuration Options",
      description = [[
        The <code>busadmin</code> accepts the following command-line arguments to define configuration options.
        Additionally, the configuration options can be provided in a Lua file.

        Usage:
        <pre>busadmin [options] [script] [args]</pre>

        Options:

        <table>
          <tr><th>Command-Line Argument</th>                         <th>Description</th></tr>
          <tr><td><code>-busref &lt;path|host:port&gt;</code></td>   <td>IOR file or address of the bus to connect.</td></tr>
          <tr><td><code>-entity &lt;name&gt;</code></td>             <td>authentication entity of the connection to the bus.</td></tr>
          <tr><td><code>-privatekey &lt;path&gt;</code></td>         <td>authentication key of the connection to the bus (login by certificate).</td></tr>
          <tr><td><code>-password &lt;text&gt;</code></td>           <td>authentication password of the connection to the bus (login by password).</td></tr>
          <tr><td><code>-domain &lt;name&gt;</code></td>             <td>authentication password domain.</td></tr>
          <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
          <tr><td><code>-sslmode &lt;mode&gt;</code></td>            <td>SSL support mode: <code>supported</code> or <code>required</code>.</td></tr>
          <tr><td><code>-sslcapath &lt;path&gt;</code></td>          <td>directory with CA certificates for SSL connection authentication.</td></tr>
          <tr><td><code>-sslcafile &lt;path&gt;</code></td>          <td>file with CA certificate for SSL connection authentication.</td></tr>
          <tr><td><code>-sslcert &lt;path&gt;</code></td>            <td>public key certificate for SSL connection authentication.</td></tr>
          <tr><td><code>-sslkey &lt;path&gt;</code></td>             <td>private key of the public key certificate provided.</td></tr>
          <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
          <tr><td><code>-loglevel &lt;number&gt;</code></td>         <td>bus access infrastruture log level (default is 0).</td></tr>
          <tr><td><code>-logfile &lt;path&gt;</code></td>            <td>bus access infrastruture log level (default is <code>STDOUT</code>).</td></tr>
          <tr><td><code>-oilloglevel &lt;number&gt;</code></td>      <td>ORB (OiL) log level (reserved).</td></tr>
          <tr><td><code>-oillogfile &lt;path&gt;</code></td>         <td>ORB (OiL) log file (reserved).</td></tr>
          <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
          <tr><td><code>-i, -interactive</code></td>                 <td>enable interactive console mode.</td></tr>
          <tr><td><code>-e, -execute &lt;code&gt;</code></td>        <td>Lua snipet to be executed.</td></tr>
          <tr><td><code>-l, -load &lt;module&gt;</code></td>         <td>name of a Lua module to be loaded.</td></tr>
          <tr><td><code>-v, -version</code></td>                     <td>shows the program version.</td></tr>
          <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
          <tr><td><code>-configs &lt;path&gt;</code></td>            <td>Lua file with configuration options to be loaded.</td></tr>
          <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
          <tr><td><code>-h, -help</code></td>                        <td>shows a message describing the command-line options.</td></tr>
        </table>
      ]],
    },
    {
      type = "table",
      title = "Authentication Operations",
      description = [[
        Functions to handle authentication in bus.
      ]],
      fields = {
        login = {
          type = "function",
          title = "Authenticates to the Bus",
          description = [[
            creates a new login in a bus with the identity of the entity provided.
            The created login is used in all following operations.
            If another login is in place at the moment this function if invoked, this current login becomes invalid if a new login is successfully created.
            If a new login cannot be created this operation fails raising an error and the current active login is left unchanged.
          ]],
          parameters = {
            {
              name = "busref",
              type = "string",
              title = "Reference to the Bus",
              description = [[
                contains the address to a bus in the form <code>host:port</code>, or a path to a file with the IOR of the bus.
              ]],
            },
            {
              name = "entity",
              type = "string",
              title = "Authentication Name",
              description = [[
                contains the name of the entity to be authenticated and associated to the login created.
              ]],
            },
            {
              name = "secret",
              type = "string",
              title = "Authentication Secret",
              description = [[
                contains a password or a path to a file with the the private key to be used in a authentication using a certificate.
                If this parameter is a password the parameter <code>domain</code> must be provided.
              ]],
              eventual = "a message is printed asking for a password to be typed (from the standard input).",
            },
            {
              name = "domain",
              type = "string",
              title = "Authentication Password Domain",
              description = [[
                contains the name of the authentication domain for the password.
              ]],
              eventual = "the value provided in <code>secret</code> is considered a path to private key file.",
            },
          },
        },
        whoami = {
          type = "function",
          title = "Gets Authentication Info",
          description = [[
            returns an object with the information about the current login.
          ]],
          results = {
            {
              type = {
                {
                  type = "logininfo",
                  description = "contains information about the current active login",
                },
                {
                  type = "nil",
                  description = "indicates there is no active connection to a bus at the moment",
                },
              },
              name = "login",
              title = "Current Authentication Info",
            },
          },
        },
        quit = {
          type = "function",
          title = "Terminates Execution",
          description = [[
            shuts down the bus access infrastructure and terminates the current thread in execution.
          ]],
        },
      },
    },
    {
      type = "table",
      title = "Login Management",
      description = [[
        Functions to manage the login of systems connected to the bus.
      ]],
      fields = {
        logins = {
          type = "function",
          title = "Lists Active Logins",
          description = [[
            list all currently active logins or the active logins of an entity.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the name of an entity which logins must be listed",
                },
                {
                  type = "logininfo",
                  description = "of the entity which logins must be listed",
                },
              },
              name = "entity",
              title = "Authentication Name",
              eventual = "this function returns all active logins, but this is only allowed when authenticated as an entity with adiministrative rights.",
            },
          },
          results = {
            {
              name = "logins",
              type = "list",
              title = "List of Logins",
              description = [[
                contains a sequence of <#logininfo> of all the logins currently active in the bus.
              ]],
            },
          },
        },
        kick = {
          type = "function",
          title = "Invalidates a Login",
          description = [[
            makes a login invalid.
            If the login provided is already invalid this method has no effect.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the ID of the login to be invalidated",
                },
                {
                  type = "logininfo",
                  description = "represents the login to be invalidated",
                },
              },
              name = "login",
              title = "Login to be Invalidated",
            },
          },
          results = {
            {
              type = "boolean",
              name = "done",
              title = "Indication of Action",
              description = [[
                is <code>true</code> when the login provided was active and was invalidated, or <code>false</code> otherwise.
              ]],
            },
          },
        },
      },
    },
    {
      type = "table",
      title = "Service Offer Management",
      description = [[
        Functions to manage service offers.
      ]],
      fields = {
        offers = {
          type = "function",
          title = "Searches Service Offers",
          description = [[
            returns all active offers that present a given set of properties.
          ]],
          parameters = {
            {
              name = "properties",
              type = "table",
              title = "Search Properties",
              description = [[
                contains a list of tables in the form <code>{name="openbus.offer.entity",value="EntityName"}</code> where field <code>name</code> indicates a property name and field <code>value</code> indicates the property value.
                Additionally, this table can contain the following fields that are translated to the indicated property.
                <table>
                  <tr><th>Field</th><th>Equivalent</th></tr>
                  <tr><td><code>id=string</code></td><td><code>{name="openbus.offer.id",value=string}</code></td></tr>
                  <tr><td><code>login=string</code></td><td><code>{name="openbus.offer.login",value=string}</code></td></tr>
                  <tr><td><code>entity=string</code></td><td><code>{name="openbus.offer.entity",value=string}</code></td></tr>
                  <tr><td><code>timestamp=string</code></td><td><code>{name="openbus.offer.timestamp",value=string}</code></td></tr>
                  <tr><td><code>year=string</code></td><td><code>{name="openbus.offer.year",value=string}</code></td></tr>
                  <tr><td><code>month=string</code></td><td><code>{name="openbus.offer.month",value=string}</code></td></tr>
                  <tr><td><code>day=string</code></td><td><code>{name="openbus.offer.day",value=string}</code></td></tr>
                  <tr><td><code>hour=string</code></td><td><code>{name="openbus.offer.hour",value=string}</code></td></tr>
                  <tr><td><code>minute=string</code></td><td><code>{name="openbus.offer.minute",value=string}</code></td></tr>
                  <tr><td><code>second=string</code></td><td><code>{name="openbus.offer.second",value=string}</code></td></tr>
                  <tr><td><code>compname=string</code></td><td><code>{name="openbus.component.name",value=string}</code></td></tr>
                  <tr><td><code>majorversion=string</code></td><td><code>{name="openbus.component.version.major",value=string}</code></td></tr>
                  <tr><td><code>minorversion=string</code></td><td><code>{name="openbus.component.version.minor",value=string}</code></td></tr>
                  <tr><td><code>patchversion=string</code></td><td><code>{name="openbus.component.version.patch",value=string}</code></td></tr>
                  <tr><td><code>platform=string</code></td><td><code>{name="openbus.component.platform",value=string}</code></td></tr>
                </table>
              ]],
              eventual = "this function returns all active offers in the bus.",
            },
          },
          results = {
            {
              name = "offers",
              type = "list",
              title = "Offers Found",
              description = [[
                contains a list <#offer> objects that represent the currently active service offers found.
              ]],
            },
          },
        },
        deloffer = {
          type = "function",
          title = "Removes a Service Offer",
          parameters = {
            {
              name = "offer",
              title = "Offer to be Removed",
              type = {
                {
                  type = "string",
                  description = "contains the ID of the offer to be removed",
                },
                {
                  type = "offer",
                  description = "represents the offer to be removed",
                },
              },
            },
          },
          results = {
            {
              name = "done",
              title = "Indication of Action",
              type = "boolean",
              description = [[
                is <code>true</code> when the offer indicated was active and was removed, or <code>false</code> otherwise.
              ]],
            },
          },
        },
      },
    },
    {
      type = "table",
      title = "Authentication Certificate Management",
      description = [[
        Functions to manage authentication certificate.
      ]],
      fields = {
        certents = {
          type = "function",
          title = "Lists Entities with Certificate",
          description = [[
            returns a list of names of all entities with an authentication certificate registered in the bus.
          ]],
          results = {
            {
              name = "certificates",
              title = "Entities with Certificate",
              type = "list",
              description = [[
                contains the names of all entities with a authentication certificate registered in the bus.
              ]],
            },
          },
        },
        delcert = {
          type = "function",
          title = "Removes an Entity Certificate",
          parameters = {
            {
              type = "string",
              name = "entity",
              title = "Entity Name of the Certificate",
              description = [[
                contains the name of the entity associated to the certificate to be removed.
              ]],
            },
          },
          results = {
            {
              type = "boolean",
              name = "done",
              title = "Indication of Action",
              description = [[
                is <code>true</code> when the login certificate indicated was registered and was removed, or <code>false</code> otherwise.
              ]],
            },
          },
        },
        setcert = {
          type = "function",
          title = "Registers an Entity Certificate",
          description = [[
            registers in the bus a public key certificate to be used for authentication as an entity name.
          ]],
          parameters = {
            {
              type = "string",
              name = "entity",
              title = "Entity Name of the Certificate",
              description = [[
                contains the name of the entity to be associated with the certificate.
              ]],
            },
            {
              type = "string",
              name = "certificate",
              title = "Certificate File Path",
              description = [[
                contains the path of a file containing a public key certificate in X.509 format to be registered.
              ]],
            },
          },
          results = {
            {
              type = "boolean",
              name = "done",
              title = "Indication of Action",
              description = [[
                is <code>true</code> when the authentication certificate was successfully registered, or <code>false</code> otherwise.
              ]],
            },
          },
        },
        getcert = {
          type = "function",
          title = "Gets an Entity Certificate",
          description = [[
            returns the authentication certificate associated with an entity name.
          ]],
          parameters = {
            {
              type = "string",
              name = "entity",
              title = "Entity Name of the Certificate",
              description = [[
                contains the name of the entity that owns the certificate to be returned.
              ]],
            },
          },
          results = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the certificate found encoded in X.509 format",
                },
                {
                  type = "nil",
                  description = "indicates no certificate is associated with the entity was found",
                },
              },
              name = "certificate",
              title = "Authentication Certificate Found",
            },
          },
        },
      },
    },
    {
      type = "table",
      title = "Entity Category Management",
      description = [[
        Functions to manage entity categories.
      ]],
      fields = {
        categories = {
          type = "function",
          title = "Lists Entity Categories",
          description = [[
            returns a list of objects representing all entity categories registered in the bus.
          ]],
          results = {
            {
              type = "list",
              name = "categories",
              title = "Entity Categories Registered",
              description = [[
                contains <#category> objects that represent all entity categories currently registered in the bus.
              ]],
            },
          },
        },
        getcategory = {
          type = "function",
          title = "Gets an Entity Category",
          description = [[
            returns an object representing an entity category specified.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the ID of the entity category to be returned",
                },
                {
                  type = "category",
                  description = "represents the entity category to be returned",
                },
              },
              name = "category",
              title = "Entity Category Identification",
            },
          },
          results = {
            {
              type = {
                {
                  type = "category",
                  description = "represents the entity category found",
                },
                {
                  type = "nil",
                  description = "indicates no entity category with the provided id was found",
                },
              },
              name = "category",
              title = "Entity Category Found",
            },
          },
        },
        setcategory = {
          type = "function",
          title = "Sets Entity Category's Description",
          description = [[
            changes the textual description of an existing entity category or registers a new entity category with the information provided.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the ID of the entity category to be modified or registered",
                },
                {
                  type = "category",
                  description = "represents the entity category to be modified or registered",
                },
              },
              name = "category",
              title = "Entity Category Identification",
            },
            {
              type = "string",
              name = "name",
              title = "Entity Category's Description",
              description = [[
                contains the textual description of the category to be modified or registered.
              ]],
            },
          },
          results = {
            {
              type = "category",
              name = "category",
              title = "Entity Category Modified",
              description = [[
                represents the entity category modified or registered.
              ]],
            },
          },
        },
        delcategory = {
          type = "function",
          title = "Unregisters an Entity Category",
          description = [[
            removes an entity category specified from the bus.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the ID of the entity category to be removed",
                },
                {
                  type = "category",
                  description = "represents the entity category to be removed",
                },
              },
              name = "category",
              title = "Entity Category to be Removed",
            },
          },
          results = {
            {
              type = {
                {
                  type = "category",
                  description = "represents the category removed",
                },
                {
                  type = "nil",
                  description = "indicates no entity category with the provided ID was found",
                },
              },
              name = "category",
              title = "Entity Category Removed",
            },
          },
        },
      },
    },
    {
      type = "table",
      title = "Registered Entity Management",
      description = [[
        Functions to manage registered entities.
      ]],
      fields = {
        entities = {
          type = "function",
          title = "Lists Registered Entities",
          description = [[
            returns a list of objects representing entities registered to be authorized to offer services in the bus.
          ]],
          parameters = {
            {
              name = "...",
              title = "Authorized Service Interfaces",
              description = [[
                are strings containing the CORBA's Repository Interface ID of service interfaces that the returned entities must be authorized to offer.
                When this parameter is string <code>"*"</code> all entities authorized to offer at least one interface are returned.
                If no service interface is provided (no parameters are provided) then all registered entities are returned.
              ]],
            },
          },
          results = {
            {
              type = "list",
              name = "entities",
              title = "Registered Entities",
              description = [[
                contains a list of <#entity> objects representing all entities currently registered to be authorized to offer services in the bus.
              ]],
            },
          },
        },
        getentity = {
          type = "function",
          title = "Gets a Registered Entity",
          description = [[
            returns an object representing the registered entity specified.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "containing the name of the entity to be returned",
                },
                {
                  type = "entity",
                  description = "represents the entity to be returned",
                },
              },
              name = "entity",
              title = "Registered Entity Identification",
            },
          },
          results = {
            {
              type = {
                {
                  type = "entity",
                  description = "represents the entity found",
                },
                {
                  type = "nil",
                  description = "indicates no entity with the provided name were found",
                },
              },
              name = "entity",
              title = "Registered Entity Found",
            },
          },
        },
        setentity = {
          type = "function",
          title = "Sets Registered Entity Description",
          description = [[
            changes the textual description of a registered entity.
            If the entity name is not registered this function raises an error.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the name of the entity to be modified",
                },
                {
                  type = "entity",
                  description = "represents the entity",
                },
              },
              name = "entity",
              title = "Registered Entity Identification",
            },
            {
              type = "string",
              name = "name",
              title = "Entity Description",
              description = [[
                contains the value to be defined as the new describing name of the entity.
              ]],
            },
          },
          results = {
            {
              name = "entity",
              type = "entity",
              title = "Registered Entity Modified",
              description = [[
                represents the registered entity modified.
              ]],
            },
          },
        },
        delentity = {
          type = "function",
          title = "Unregisters Entity",
          description = [[
            removes the registration for offer authorization of an entity from the bus.
          ]],
          parameters = {
            {
              type = {
                {
                  type = "string",
                  description = "contains the name of the entity to be unregistered",
                },
                {
                  type = "entity",
                  description = "represents the entity to be unregistered",
                },
              },
              name = "entity",
              title = "Registered Entity Identification",
            },
          },
          results = {
            {
              type = {
                {
                  type = "entity",
                  description = "represents the entity unregistered",
                },
                {
                  type = "nil",
                  description = "indicates no entity was found",
                },
              },
              name = "entity",
              title = "Unregistered Entity",
            },
          },
        },
      },
    },
    {
      type = "table",
      title = "Service Interface Management",
      description = [[
        Functions to manage service interface offered in the bus.
      ]],
      fields = {
        ifaces = {
          type = "function",
          title = "Lists Registered Interfaces",
          description = [[
            returns a list of CORBA Interface Repository IDs for every service interface registered in the bus.
          ]],
          results = {
            {
              type = "list",
              name = "interfaces",
              title = "Registered Interfaces",
              description = [[
                contains strings containing the CORBA's Interface Repository ID of each service interfaces registered in the bus.
              ]],
            },
          },
        },
        addiface = {
          type = "function",
          title = "Registers a Service Interface",
          description = [[
            registers in the bus a service interface so it can be authorized to be offered by systems connected to the bus.
          ]],
          parameters = {
            {
              name = "interface",
              type = "string",
              title = "Service Interface to be Registered",
              description = [[
                contains the CORBA's Interface Repository ID of the service interface to be registered.
              ]],
            },
          },
          results = {
            {
              type = "boolean",
              name = "done",
              title = "Indication of Action",
              description = [[
                is <code>true</code> when the interface was not previously registered and is now registered, or <code>false</code> otherwise.
              ]],
            },
          },
        },
        deliface = {
          type = "function",
          title = "Unregisters a Service Interface",
          description = [[
            unregisters a service interface from the bus, so it cannot be authorized to be offered by systems connected to the bus.
          ]],
          parameters = {
            {
              type = "string",
              name = "interface",
              title = "Service Interface to be Unregistered",
              description = [[
                contains the CORBA's Interface Repository ID of the service interface to be unregistered.
              ]],
            },
          },
          results = {
            {
              type = "boolean",
              name = "done",
              title = "Indication of Action",
              description = [[
                is <code>true</code> when the interface was registered and is now unregistered, or <code>false</code> otherwise.
              ]],
            },
          },
        },
      },
    },
    {
      type = "table",
      title = "Governance Descriptor Factory",
      description = [[
        Function to create governance descriptor objects.
      ]],
      fields = {
        newdesc = {
          type = "function",
          title = "Creates a Governance Descriptor",
          description = [[
            creates a new governance descriptor object that can be used to store governance definitions of a bus, like entity authentication certificates and service interface offer authorizations.
            The governance descriptions are LUA files. Normally they're generated by the governance descriptor object but in previous versions they were written manually. The syntax is as follows:
            
            <pre>
            -- Category definition
            -- * command: Category
            -- * parameters:
            --   * id = category identifier
            --   * name = category description
            Category {
              id = "TEST_Category",
              name = "Category description",
            }
            -- Entity definition
            -- * command: Entity
            -- * parameters:
            --   * id = entity identifier
            --   * category = Entity's category identifier
            --   * name = entity description
            Entity {
              id = "TEST_Entity",
              category = "TEST_Category",
              name = "Entity description",
            }
            -- Certificate definition
            -- * command: Certificate
            -- * parameters:
            --   * id = entity identifier
            --   * certificate = path to the entity's certificate file
            Certificate {
              id = "TEST_Entity",
              certificate = "test.crt",
            }
            -- Interface definition
            -- * command: Interface
            -- * parameters:
            --   * id = interface's repID
            Interface {
              id = "IDL:script/Test:1.0"
            }
            -- Grant authorization
            -- * command: Grant
            -- * parameters:
            --   * id = identifier of the entity to be authorized
            --   * interfaces = list of interfaces to be authorized
            Grant {
              id = "TEST_Entity",
              interfaces = {
                "IDL:script/Test:1.0",
              }
            }
            -- Revoke authorization
            -- * command: Revoke
            -- * parameters:
            --   * id = entity identifier
            --   * interfaces = list of interfaces to be de-authorized
            Revoke {
              id = "TEST_Entity",
              interfaces = {
                "IDL:script/Test:1.0",
              }
            }
            </pre>
          ]],
          results = {
            {
              type = "descriptor",
              name = "descriptor",
              title = "Governance Descriptor",
              description = [[
                is the newly created governance descriptor object.
              ]],
            },
          },
        },
      },
    },
    {
      type = "table",
      title = "Core Services Management and Configuration",
      description = [[
        Functions to manage the core services, i.e: life-cycle, configuration, etc.
      ]],
      fields = {
        reloadconf = {
          type = "function",
          title = "Reloads the Configuration File",
          description = [[
            reset all configurations to default values defined in the configuration file.
          ]],
        },
        grantadmin = {
          type = "function",
          title = "Grants Admin privilegies to Entities",
          description = [[
            adds entities to the list of granted entities to perform administrative operations. 
          ]],
          parameters = {
            {
              type = "list",
              name = "entities",
              title = "List of entity names to be granted",
              description = [[
                contains strings with the name of each entity to be granted.
              ]],
            },
          },
        },
        revokeadmin = {
          type = "function",
          title = "Revokes Admin Privilegies from Entities",
          description = [[
            removes entities from list of granted entities to perform administrative operations. 
          ]],
          parameters = {
            {
              type = "list",
              name = "entities",
              title = "List of entity names to be revoked",
              description = [[
                contains strings with the name of each entity to be revoked.
              ]],
            },
          },
        },
        admins = {
          type = "function",
          title = "Lists the Names of Entities with Admin Privilegies",
          description = [[
            returns a list of entity names able to perform administrative operations.
          ]],
          results = {
            {
              name = "entities",
              type = "list",
              title = "Administrative entities",
              description = [[
                contains strings with the name of each entity granted to perform administrative operations.
              ]],
            },
          },
        },
        addpasswordvalidator = {
          type = "function",
          title = "Loads a Password Validator",
          description = [[
            loads a password validator to current password validation mechanism of a domain. 
            If the validator is already loaded, this operation has no effect.
          ]],
          parameters = {
            {
              type = "string",
              name = "specification",
              title = "Password validator specification",
              description = [[
                is separated by a colon (i.e. "domain:validatormodule") which the
                first substring specifies the validation domain and the second 
                substring specifies the Lua Module to be loaded.
              ]],
            },
          },
        },
        delpasswordvalidator = {
          type = "function",
          title = "Unloads a Password Validator",
          description = [[
            unloads a password validator from current validation mechanism of a domain.
            If the validator is already unloaded, this operation has no effect.
          ]],
          parameters = {
            {
              type = "string",
              name = "specification",
              title = "Password validator specification",
              description = [[
                is separated by a colon (i.e. "domain:validatormodule") which the 
                first substring specifies the validation domain and the second 
                substring specifies the Lua Module to be unloaded.
              ]],
            },
          },
        },
        passwordvalidators = {
          type = "function",
          title = "Lists the Current Password Validators Loaded",
          description = [[
            retuns a list of password validator specifications currently being used.
          ]],
          results = {
            {
              type = "list",
              name = "specifications",
              title = "A list of password validator specifications",
              description = [[
                 contains a set of colon separated strings (i.e. "domain:validatormodule")
                 which the first substring specifies the validation domain and the second
                 substring specifies the Lua Module loaded.
              ]],
            },
          },
        },
        addtokenvalidator = {
          type = "function",
          title = "Loads a Token Validator",
          description = [[
            loads a token validator to current token validation mechanism of a domain. 
            If the validator is already loaded, this operation has no effect.
          ]],
          parameters = {
            {
              type = "string",
              name = "specification",
              title = "Token validator specification",
              description = [[
                is separated by a colon (i.e. "domain:validatormodule") which the 
                first substring specifies the validation domain and the second
                substring specifies the Lua Module to be loaded.
              ]],
            },
          },
        },
        deltokenvalidator = {
          type = "function",
          title = "Unloads a Token Validator",
          description = [[
            unloads a token validator from current validation mechanism of a domain. 
            If the validator is already unloaded, this operation has no effect.
          ]],
          parameters = {
            {
              type = "string",
              name = "specification",
              title = "Token validator specification",
              description = [[
                is separated by a colon (i.e. "domain:validatormodule") which the 
                first substring specifies the validation domain and the second 
                substring specifies the Lua Module to be unloaded.
              ]],
            },
          },
        },
        tokenvalidators = {
          type = "function",
          title = "Lists the Current Token Validators Loaded",
          description = [[
            retuns a list of token validator specifications currently being used.
          ]],
          results = {
            {
              type = "list",
              name = "specifications",
              title = "A list of token validator specifications",
              description = [[
                 contains a set of colon separated strings (i.e. "domain:validatormodule") 
                 which the first substring specifies the validation domain and the second
                 substring specifies the Lua Module loaded.
              ]],
            },
          },
        },
        maxchannels = {
          type = "function",
          title = "Gets and Sets the Limit of TCP Channels Managed by OiL",
          description = [[
            configures the current maximum channels limit configured in OiL or sets a new limit.
          ]],
          parameters = {
            {
              type = "number",
              name = "max",
              title = "The maximum TCP channels used in OiL",
              description = [[
                updates the value of maximum TCP channels managed by OiL.
              ]],
              eventual = [[
                returns the current value of maximum TCP channels.
              ]],
            },
          },
          results = {
            {
              type = "number",
              name = "max",
              description = [[
                returns the current value of maximum TCP channels managed by OiL.
              ]],
              eventual = [[
                some value was provided as parameter.
              ]],
            },
          },
        },
        maxcachesize = {
          type = "function",
          title = "Gets and Sets the Limit of All LRU Caches",
          description = [[
            configures the current maximum size of LRU caches. 
            There is three independent caches for OpenBus protocol related communications 
            (i.e. IOR profile cache, session incoming cache, session outgoing cache) and 
            they use the same maximum size.
          ]],
          parameters = {
            {
              type = "number",
              name = "max",
              title = "The maximum size of all LRU caches",
              description = [[
                updates the value of maximum size of LRU caches.
              ]],
              eventual = [[
                returns the current value of maximum size of LRU caches.
              ]],
            },
          },
          results = {
            {
              type = "number",
              name = "max",
              description = [[
                returns the current value of maximum size of LRU caches.
              ]],
              eventual = [[
                some value was provided as parameter.
              ]],
            },
          },
        },
        loglevel = {
          type = "function",
          title = "Gets and Sets the Log Level of Bus Core Services",
          description = [[
            configures the current log level of bus core services.
          ]],
          parameters = {
            {
              type = "number",
              name = "level",
              title = "The log level of bus core services",
              description = [[
                updates the value of log level in bus core services.
              ]],
              eventual = [[
                returns the current log level.
              ]],
            },
          },
          results = {
            {
              type = "number",
              name = "level",
              description = [[
                returns the current log level used in bus core services.
              ]],
              eventual = [[
                some value was provided as parameter.
              ]],
            },
          },
        },
        oilloglevel = {
          type = "function",
          title = "Gets and Sets the OiL Log Level OiL of Bus Core Services",
          description = [[
            configures the current OiL log level of bus core services. 
            Increase the OiL log level will generate a huge amount of log.
          ]],
          parameters = {
            {
              type = "number",
              name = "level",
              title = "The OiL log level of bus core services",
              description = [[
                updates the value of OiL log level in bus core services.
              ]],
              eventual = [[
                returns the current OiL log level.
              ]],
            },
          },
          results = {
            {
              type = "number",
              name = "level",
              description = [[
                returns the current OiL log level used in bus core services. 
              ]],
              eventual = [[
                some value was provided as parameter.
              ]],
            },
          },
        },
        shutdown = {
          type = "function",
          title = "Shuts Down the Core Services",
          description = [[
            calls the bus to shut down itself. 
            This operation must be executed by OpenBus special entity 
            otherwise a NO_PERMISSION exception will be raised.
          ]],
        },
      }
    },
    set = {
      type = "table",
      title = "Value Set",
      description = [[
        contains values stored as keys, therefore it cannot contain duplicates and elements are stored without a particular order.
      ]],
      fields = {
        __tostring = ToStringMetaMethod(),
      },
    },
    list = {
      type = "table",
      title = "Value Sequence",
      description = [[
        contains a sequence of values using integer keys starting from 1.
      ]],
      fields = {
        __tostring = ToStringMetaMethod(),
      },
    },
    logininfo = {
      type = "table",
      title = "Login Information",
      description = [[
        contains information about a login in the bus.
      ]],
      fields = {
        __tostring = ToStringMetaMethod(),
        id = {
          type = "string",
          title = "Login Identifier",
        },
        entity = {
          type = "string",
          title = "Login's Entity Name",
        },
      },
    },
    offerprops = {
      type = "table",
      title = "Service Offer Properties",
      description = [[
        contains a sequence of tables describing offer properties in the form <code>{name="openbus.offer.entity",value="EntityName"}</code> where field <code>name</code> indicates a property name and field <code>value</code> indicates the property value.
      ]],
      fields = {
        __tostring = ToStringMetaMethod(),
      },
    },
    offer = {
      type = "table",
      title = "Service Offer",
      description = [[
        represents a service offer registered in the bus.
      ]],
      fields = {
        __tostring = ToStringMetaMethod(),
        properties = {
          type = "offerprops",
          title = "Offer Properties",
        },
        id = {
          type = "string",
          title = "Value of Property <code>openbus.offer.id</code>",
        },
        login = {
          type = "string",
          title = "Value of Property <code>openbus.offer.login</code>",
        },
        entity = {
          type = "string",
          title = "Value of Property <code>openbus.offer.entity</code>",
        },
        timestamp = {
          type = "string",
          title = "Value of Property <code>openbus.offer.timestamp</code>",
        },
        year = {
          type = "string",
          title = "Value of Property <code>openbus.offer.year</code>",
        },
        month = {
          type = "string",
          title = "Value of Property <code>openbus.offer.month</code>",
        },
        day = {
          type = "string",
          title = "Value of Property <code>openbus.offer.day</code>",
        },
        hour = {
          type = "string",
          title = "Value of Property <code>openbus.offer.hour</code>",
        },
        minute = {
          type = "string",
          title = "Value of Property <code>openbus.offer.minute</code>",
        },
        second = {
          type = "string",
          title = "Value of Property <code>openbus.offer.second</code>",
        },
        compname = {
          type = "string",
          title = "Value of Property <code>openbus.component.name</code>",
        },
        majorversion = {
          type = "string",
          title = "Value of Property <code>openbus.component.version.major</code>",
        },
        minorversion = {
          type = "string",
          title = "Value of Property <code>openbus.component.version.minor</code>",
        },
        patchversion = {
          type = "string",
          title = "Value of Property <code>openbus.component.version.patch</code>",
        },
        platform = {
          type = "string",
          title = "Value of Property <code>openbus.component.platform</code>",
        },
        facets = {
          type = "set",
          title = "Value of Properties <code>openbus.component.facet</code>",
          description = [[
            contains all values of properties <code>openbus.component.facet</code>.
          ]],
        },
        interfaces = {
          type = "set",
          title = "Value of Properties <code>openbus.component.interface</code>",
          description = [[
            contains all values of properties <code>openbus.component.interface</code>.
          ]],
        },
      },
    },
    category = {
      type = "table",
      title = "Entity Category",
      description = [[
        represents a registered category of entities registered to be authorized to offer services in the bus.
      ]],
      fields = {
        __tostring = ToStringMetaMethod(),
        entities = {
          type = "method",
          title = "Returns Entities in the Category",
          description = [[
            returns the entities registered in the category.
          ]],
          results = {
            {
              name = "entities",
              type = "list",
              title = "Registered Entities",
              description = [[
                contains <#entity> objects representing all entities currently registered in the category.
              ]],
            },
          },
        },
        {
          name = "addentity",
          type = "method",
          title = "Registers Entity in the Category",
          description = [[
            registers an entity in the category so it can be authorized to offer services in the bus.
          ]],
          parameters = {
            {
              type = "string",
              name = "name",
              title = "Entity Name",
              description = [[
                contains the name of the entity to be registered.
              ]]
            },
            {
              type = "string",
              name = "description",
              title = "Entity's Description",
              description = [[
                contains the textual description of the entity to be registered.
              ]],
            },
          },
          results = {
            {
              type = "entity",
              name = "entity",
              title = "Entity to be Registered",
              description = [[
                represents the entity to be registered.
              ]],
            },
          },
        },
      },
    },
    entity = {
      type = "table",
      title = "Registered Entity",
      description = [[
        represents an entity registered in the bus to be authorized to offer services.
      ]],
      fields = {
        __tostring = ToStringMetaMethod(),
        category = {
          type = "method",
          title = "Returns Entity's Category",
          description = [[
            returns the category in which the entity is registered.
          ]],
          results = {
            {
              name = "category",
              type = "category",
              title = "Entity's Category",
              description = [[
                represents the entity's category.
              ]],
            },
          },
        },
        grant = {
          type = "method",
          title = "Authorizes Entity to Offer Interface",
          description = [[
            grants the entity the authorization to offer a service that implement the specified interface.
          ]],
          parameters = {
            {
              type = "string",
              name = "interface",
              title = "Service Interface to be Authorized",
              description = [[
                contains the CORBA's Interface Repository ID of the service interface to be authorized.
              ]],
            },
          },
          results = {
            {
              type = "boolean",
              name = "done",
              title = "Indication of Action",
              description = [[
                is <code>true</code> when the interface was not authorized and now is, or <code>false</code> otherwise.
              ]],
            },
          },
        },
        revoke = {
          type = "method",
          title = "Unauthorizes Entity to Offer Interface",
          description = [[
            revokes the authorization of the entity to offer a service with the specified interface.
          ]],
          parameters = {
            {
              type = "string",
              name = "interface",
              title = "Service Interface to be Unauthorized",
              description = [[
                contains the CORBA's Interface Repository ID of the service interface to be revoked.
              ]],
            },
          },
          results = {
            {
              type = "boolean",
              name = "done",
              title = "Indication of Action",
              description = [[
                is <code>true</code> when the interface was authorized and now is unauthorized, or <code>false</code> otherwise.
              ]],
            },
          },
        },
        ifaces = {
          type = "method",
          title = "Lists Authorized Interfaces",
          description = [[
            returns a list of CORBA Interface Repository IDs for every service interface that the entity is authorized to offer.
          ]],
          results = {
            {
              type = "list",
              name = "interfaces",
              title = "Authorized Interfaces",
              description = [[
                contains of all CORBA's Interface Repository ID of the authorized service interfaces.
              ]],
            },
          },
        },
      },
    },
    descriptor = {
      type = "table",
      title = "Governance Descriptor",
      description = [[
        contains a description of the governance definitions of a bus.
      ]],
      fields = {
        quiet = {
          type = {{type="boolean"},{type="nil"}},
          title = "Quiet Flag",
          description = [[
            indicates which action to take when there are conflicts while importing definitions from a file or a bus.
            The following list describe the possible values:
            <dl>
              <dt><code>true</code></dt>
              <dd>All conflicts and errors are resolved automatically priorizing the lastest definitions whenever possible.</dd>
              <dt><code>false</code></dt>
              <dd>All conflicts and errors are ignored maintaining the earliest definitions whenever possible.</dd>
              <dt><code>nil</code></dt>
              <dd>All conflicts and errors gererates a question that is printed in the standard output and waits for a anwser interactively from the standard input.</dd>
            </dl>
          ]],
        },
        import = {
          type = "method",
          title = "Import from File",
          description = [[
            imports to the descriptor the definitions defined in a file.
            The file must contain a Lua code that creates definitions using the format of Bus Governance Descriptor.
          ]],
          parameters = {
            {
              type = "string",
              name = "path",
              title = "File Path",
              description = [[
                contains the path of file containig Lua code that creates the definitions to the loaded to the descriptor.
              ]],
            },
            {
              name = "...",
              title = "File Arguments",
              description = [[
                are values to be passed to the Lua code contained in the file.
              ]],
            },
          },
        },
        export = {
          type = "method",
          title = "Export to File",
          description = [[
            exports every definition in the descriptor to a file using the format of Bus Governance Descriptor.
          ]],
          parameters = {
            {
              type = "string",
              name = "path",
              title = "File Path",
              description = [[
                contains the path of file where the definitions of the descriptor must be written.
              ]],
            },
            {
              type = "string",
              name = "certpath",
              title = "Certificate Directory Path",
              description = [[
                contains the path to a directory where the entity authentication certificates must be written.
                These authentication certificates are written in individual files using as file name the MD5 hash of the certificate in DER format.
              ]],
            },
            {
              type = "string",
              name = "mode",
              title = "Export Mode",
              description = [[
                can be one of the following values:
                <dl>
                  <dt><code>"legacy"</code></dt>
                  <dd>The file generated uses the legacy format, which is supported both by OpenBus 2.0 and 2.1.</dd>
                  <dt><code>"compact"</code></dt>
                  <dd>The file generated follows a more compact format where service interfaces are not declared individually and are only described when the interface is effectivelly authorized.
                  This compact format is only supported by OpenBus 2.1.</dd>
                </dl>
              ]],
              eventual = "the format of the file generated is the new format that is only supported in OpenBus 2.1.",
            },
          },
        },
        download = {
          type = "method",
          title = "Download from Bus",
          description = [[
            imports to the descriptor the definitions from the bus currently connected.
            If there is an error while accessing the bus this operation raises the error.
          ]],
        },
        upload = {
          type = "method",
          title = "Upload to Bus",
          description = [[
            exports every definition in the descriptor to the bus currently connected.
            If there is an error while accessing the bus this operation raises the error.
          ]],
        },
        revert = {
          type = "method",
          title = "Remove from Bus",
          description = [[
            removes from the bus currently connected every definition in the descriptor.
            If there is an error while accessing the bus this operation raises the error.
          ]],
        },
      },
    },
  },
}
