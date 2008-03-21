/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <CORBA.h>
#include <mico/throw.h>

#ifndef __CORE_H__
#define __CORE_H__








namespace openbusidl
{

typedef char* UUID;
typedef CORBA::String_var UUID_var;
typedef CORBA::String_out UUID_out;

typedef char* Identifier;
typedef CORBA::String_var Identifier_var;
typedef CORBA::String_out Identifier_out;

typedef SequenceTmpl< CORBA::Octet,MICO_TID_OCTET> OctetSeq;
typedef TSeqVar< SequenceTmpl< CORBA::Octet,MICO_TID_OCTET> > OctetSeq_var;
typedef TSeqOut< SequenceTmpl< CORBA::Octet,MICO_TID_OCTET> > OctetSeq_out;

}


#ifndef MICO_CONF_NO_POA

#endif // MICO_CONF_NO_POA

#endif
